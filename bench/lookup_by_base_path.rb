# /usr/bin/env ruby

require ::File.expand_path("../../config/environment", __FILE__)

require "benchmark"

require "stackprof"

abort "Refusing to run outside of development" unless Rails.env.development?

benchmarks = Location.order("RANDOM()").limit(10).pluck(:base_path)
states = %w[published unpublished]

benchmarks.each do |base_path|
  queries = 0
  ActiveSupport::Notifications.subscribe("sql.active_record") { |_| queries += 1 }
  puts base_path
  StackProf.run(mode: :wall, out: "tmp/lookup_by_base_path_#{base_path.gsub(/\//, '_').downcase}_wall.dump") do
    puts(Benchmark.measure {
      10.times do
        Edition
          .where(state: states, base_path: [base_path])
          .pluck(:base_path, :content_id)
          .uniq
        print "."
      end
    })
  end
  puts "queries: #{queries}"
  puts ""
end
