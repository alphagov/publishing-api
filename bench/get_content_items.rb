# /usr/bin/env ruby

require ::File.expand_path("../../config/environment", __FILE__)

require "benchmark"

require "stackprof"

abort "Refusing to run outside of development" unless Rails.env.development?

search = (ARGV.first == "--search")

params = {
  document_types: %w[taxon organisation topic mainstream_browse_page policy],
  fields: %w[content_id document_type title base_path],
}
params.merge(q: "school", search_in: ["details.internal_name"]) if search

queries = 0
ActiveSupport::Notifications.subscribe("sql.active_record") { |_| queries += 1 }
StackProf.run(mode: :wall, out: "tmp/get_editions_wall.dump") do
  puts(Benchmark.measure do
    10.times do
      Presenters::ResultsPresenter.new(
        Queries::GetContentCollection.new(params),
        Pagination.new,
        "http://dev.gov.uk",
      ).present
      print "."
    end
  end)
end
puts "queries: #{queries}"
puts ""
