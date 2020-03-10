# /usr/bin/env ruby

require ::File.expand_path("../../config/environment", __FILE__)
require "benchmark"

require "stackprof"

large_reverse = Link.find_by_sql(<<-SQL).first[:target_content_id]
  SELECT target_content_id
  FROM links
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

benchmarks = {
  "Many reverse dependencies" => large_reverse,
  "Many forward dependencies" => large_forward,
  "No dependencies" => no_links,
  "Single link each way" => single_link,
  "Import export topic" => "4bda0be5-3e65-4cc1-850c-0541e95a40ca",
}

benchmarks.each do |name, content_id|
  content_item_ids = Queries::GetLatest.(
    Edition.where(content_id: content_id, state: :published),
  ).pluck(:id)

  edition = Edition.where(id: content_item_ids).first

  puts "#{name}: #{content_id}"
  StackProf.run(mode: :wall, out: "tmp/downstream_presenter_#{name.gsub(/ +/, '_').downcase}_wall.dump") do
    puts(Benchmark.measure {
      10.times do |_i|
        Presenters::EditionPresenter.new(
          edition, draft: false
        )
        print "."
      end
      puts ""
    })
  end
end
