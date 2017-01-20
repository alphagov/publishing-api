# /usr/bin/env ruby

require ::File.expand_path('../../config/environment', __FILE__)

require 'benchmark'

require 'stackprof'

abort "Refusing to run outside of development" unless Rails.env.development?

queries = 0
ActiveSupport::Notifications.subscribe("sql.active_record") { |_| queries += 1 }
StackProf.run(mode: :wall, out: "tmp/get_editions_wall.dump") do
  puts Benchmark.measure {
    10.times do
      Presenters::ResultsPresenter.new(
        Queries::GetContentCollection.new(
          document_types: ['taxon', 'organisation', 'topic', 'mainstream_browse_page', 'policy'],
          fields: ['content_id', 'document_type', 'title', 'base_path']
        ),
        Pagination.new,
        'http://dev.gov.uk'
      ).present
      print "."
    end
  }
end
puts "queries: #{queries}"
puts ""
