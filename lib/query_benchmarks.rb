require 'benchmark'
include Benchmark

module QueryBenchmarks
  LABEL_WIDTH = 7
  ITERATIONS = 10

  class ContentCollectionBenchmark
    CONTENT_FORMAT = "organisation"
    FIELDS = %w(content_id format title base_path)
    PUBLISHING_APP = ""

    def self.organisations!
      Queries::GetContentCollection.new(content_format: CONTENT_FORMAT, fields: FIELDS, publishing_app: PUBLISHING_APP).call
    end

    def self.run!(name, &block)
      Benchmark.benchmark(CAPTION, LABEL_WIDTH, FORMAT, "total: ", "avg: ") do |bm|
        sum = Benchmark::Tms.new
        ITERATIONS.times do
          sum += bm.report(name, &block)
        end
        [sum, sum / ITERATIONS.to_f]
      end
    end

    def self.run_organisations!
      run!("organisations") { self.organisations! }
    end
  end
end
