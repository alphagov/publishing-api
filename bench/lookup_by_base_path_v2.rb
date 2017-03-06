# /usr/bin/env ruby

require ::File.expand_path('../../config/environment', __FILE__)

require 'benchmark'

require 'stackprof'

abort "Refusing to run outside of development" unless Rails.env.development?

benchmarks = Edition.order("RANDOM()").limit(10).pluck(:base_path)

benchmarks.each do |base_path|
  queries = 0
  ActiveSupport::Notifications.subscribe("sql.active_record") { |_| queries += 1 }
  puts base_path
  StackProf.run(mode: :wall, out: "tmp/lookup_by_base_path_v2_#{base_path.gsub(/\//, '_').downcase}_wall.dump") do
    puts Benchmark.measure {
      10.times do
        Queries::LookupByBasePaths.call([base_path])
        print "."
      end
    }
  end
  puts "queries: #{queries}"
  puts ""
end

batch = Edition.order("RANDOM()").limit(100).pluck(:base_path)
StackProf.run(mode: :wall, out: "tmp/lookup_by_base_path_v2_many}_wall.dump") do
  puts "Batch of 100 base paths"
  puts Benchmark.measure {
    10.times do
      Queries::LookupByBasePaths.call(batch)
      print "."
    end
  }
end
