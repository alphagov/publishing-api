# /usr/bin/env ruby

require ::File.expand_path('../../config/environment', __FILE__)

require 'benchmark'

require 'stackprof'

abort "Refusing to run outside of development" unless Rails.env.development?

benchmarks = Edition.order("RANDOM()").limit(10).pluck(:base_path)
states = %w(published unpublished)

def reference_implementation(base_paths, states)
  base_paths_and_content_ids = Edition.with_document
    .left_outer_joins(:unpublishing)
    .where(state: states, base_path: base_paths)
    .where("state = 'published' OR unpublishings.type = 'withdrawal'")
    .where("document_type NOT IN ('gone', 'redirect')")
    .pluck(:base_path, 'documents.content_id')
    .uniq

  Hash[base_paths_and_content_ids]
end

benchmarks.each do |base_path|
  queries = 0
  ActiveSupport::Notifications.subscribe("sql.active_record") { |_| queries += 1 }
  puts base_path
  StackProf.run(mode: :wall, out: "tmp/lookup_by_base_path_#{base_path.gsub(/\//, '_').downcase}_wall.dump") do
    puts Benchmark.measure {
      10.times do
        reference_implementation([base_path], states)
        print "."
      end
    }
  end
  puts "queries: #{queries}"
  puts ""
end

batch = Edition.order("RANDOM()").limit(100).pluck(:base_path)
StackProf.run(mode: :wall, out: "tmp/lookup_by_base_path_many}_wall.dump") do
  puts "Batch of 100 base paths"
  puts Benchmark.measure {
    10.times do
      reference_implementation(batch, states)
      print "."
    end
  }
end
