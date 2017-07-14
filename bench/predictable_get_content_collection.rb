# /usr/bin/env ruby

require ::File.expand_path("../../config/environment", __FILE__)

require "benchmark"
require "stackprof"

abort "Refusing to run outside of development" unless Rails.env.development?

StackProf.run(mode: :wall, out: "tmp/predictable_get_content_collection.dump") do
  puts Benchmark.measure {
    results = Queries::GetContentCollection.new(
      fields: ["content_id"],
      filters: {
        states: "published"
      },
      pagination: Pagination.new,
    )

    Presenters::ResultsPresenter.new(results, Pagination.new, 'http://dev.gov.uk').present
  }
end
