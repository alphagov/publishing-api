# /usr/bin/env ruby

require ::File.expand_path("../../config/environment", __FILE__)
require "benchmark"

require "stackprof"

abort "Refusing to run outside of development" unless Rails.env.development?

large_reverse = Link.find_by_sql(<<-SQL).first[:target_content_id]
  SELECT target_content_id
  FROM links
  WHERE links.link_type = 'parent'
  GROUP BY target_content_id
  ORDER BY COUNT (*) DESC
  LIMIT 1
SQL

large_forward = LinkSet.find_by_sql(<<-SQL).first[:content_id]
  SELECT content_id
  FROM link_sets
  WHERE id IN (
    SELECT link_set_id
    FROM links
    WHERE link_set_id IS NOT NULL
    GROUP BY link_set_id
    ORDER BY COUNT(*) DESC
    LIMIT 1
  )
SQL

no_links = Link.find_by_sql(<<-SQL).first[:content_id]
  SELECT content_id
  FROM link_sets
  LEFT JOIN links
  ON links.link_set_id = link_sets.id
  OR links.target_content_id = link_sets.content_id
  WHERE links.id IS NULL
  LIMIT 1
SQL

single_link = Link.find_by_sql(<<-SQL).first[:content_id]
  SELECT content_id
  FROM link_sets
  INNER JOIN links ON links.target_content_id = link_sets.content_id
  GROUP BY content_id
  HAVING COUNT(*) = 1
  LIMIT 1
SQL

def get_content_id_and_locale(content_id)
  [
      content_id,
      Document.where(content_id: content_id).pluck(:locale).first,
  ]
end

benchmarks = {
  "Many reverse dependencies" => get_content_id_and_locale(large_reverse),
  "Many forward dependencies" => get_content_id_and_locale(large_forward),
  "No dependencies" => get_content_id_and_locale(no_links),
  "Single link each way" => get_content_id_and_locale(single_link),
}

if ARGV[0] ==  "--show-queries"
  ActiveRecord::LogSubscriber::IGNORE_PAYLOAD_NAMES.delete("SCHEMA")
  ActiveRecord::Base.logger = Logger.new(STDOUT)
end

benchmarks.each do |name, (content_id, locale)|
  queries = Hash.new 0
  query_total_duration_by_name = Hash.new 0
  ActiveSupport::Notifications.subscribe("sql.active_record") do |_, started, finished, _, data|
    queries[data[:name]] += 1
    query_total_duration_by_name[data[:name]] += finished - started
  end

  result = nil
  puts "#{name}: #{content_id}"
  StackProf.run(mode: :wall, out: "tmp/downstream_mediator_#{name.gsub(/ +/, "_").downcase}_wall.dump") do
    tms = Benchmark.measure {
      10.times do
        result = Queries::GetExpandedLinks.call(content_id, locale)
        print "."
      end
    }
    puts tms
  end
  puts "queries: #{queries}"
  puts "total: #{queries.map(&:last).sum}"
  puts "query time: #{query_total_duration_by_name}"
  puts ""

  log_file = "log/#{name.parameterize}.output"
  puts "log file written to #{log_file}"
  File.open(log_file, "w") { |file| file.write(JSON.pretty_generate(result)) }
end
