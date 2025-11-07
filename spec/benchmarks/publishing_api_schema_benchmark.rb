TestCase = Data.define(
  :base_path,
  :schema_name,
  :expected_response_min_size,
  :max_sql_query_count,
  :max_single_query_time,
  :max_overall_time,
)

RSpec.describe PublishingApiSchema do
  test_config = YAML.load_file(
    Rails.root.join("spec/benchmarks/publishing_api_schema_test_cases.yaml"),
    symbolize_names: true,
  )
  defaults = test_config.fetch(:defaults)
  test_cases = test_config.fetch(:test_cases).map { |test_case| TestCase.new(**defaults.merge(test_case)) }

  test_cases.each do |test_case|
    it "should efficiently render #{test_case.schema_name} example - #{test_case.base_path}" do
      query = File.read(Rails.root.join("app/graphql/queries/#{test_case.schema_name}.graphql"))
      instrumentation_result = instrument do
        response = PublishingApiSchema.execute(query, variables: { base_path: test_case.base_path }).to_hash
        expect(response.key?("errors")).to be false
        edition = response.dig("data", "edition")
        expect(edition).to_not be nil
        expect(JSON.generate(edition).bytesize).to be > test_case.expected_response_min_size
      end

      aggregate_failures do
        expect(instrumentation_result.queries.count).to be <= test_case.max_sql_query_count
        expect(instrumentation_result.queries).to all(be_fast_query(threshold: test_case.max_single_query_time))
        expect(instrumentation_result).to be_fast_overall(threshold: test_case.max_overall_time)
      end
    end
  end
end
