# /usr/bin/env ruby

require ::File.expand_path("../../config/environment", __FILE__)

require "benchmark"

require "stackprof"

abort "Refusing to run outside of development" unless Rails.env.development?

benchmarks = Edition.where(document_type: %w[taxon organisation topic mainstream_browse_page policy need]).pluck(:document_type).uniq

benchmarks.each do |document_type|
  queries = 0
  ActiveSupport::Notifications.subscribe("sql.active_record") { |_| queries += 1 }
  puts document_type.to_s
  StackProf.run(mode: :wall, out: "tmp/linkable_mediator_#{document_type.gsub(/ +/, '_').downcase}_wall.dump") do
    puts(Benchmark.measure {
      10.times do
        Rails.cache.clear
        Queries::GetLinkables.new(
          document_type: document_type,
        ).call
        print "."
      end
    })
  end
  puts "queries: #{queries}"
  puts ""
end
