ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../config/environment", __dir__)

require "rspec/rails"

ActiveRecord::Base.establish_connection(:benchmark)

module BenchmarkHelpers
  Result = Data.define(:queries, :overall_time, :profile)

  def instrument(&block)
    queries = []
    callback = lambda do |_name, start, finish, _id, payload|
      next if payload[:name].in?(%w[SCHEMA TRANSACTION])

      queries << { sql: payload[:sql], time: finish - start }
    end

    profile_data = nil
    time = Benchmark.realtime do
      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        profile_data = StackProf.run(mode: :wall, raw: true, &block)
      end
    end

    Result.new(queries, time, profile_data)
  end
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.disable_monkey_patching!
  config.expose_dsl_globally = false

  config.infer_spec_type_from_file_location!
  config.example_status_persistence_file_path = "spec/examples.txt"

  config.use_transactional_fixtures = true
  config.include BenchmarkHelpers
end

RSpec::Matchers.define :be_fast_query do |threshold: 0.001|
  description { "be a SQL query that completes under #{threshold}s" }

  match do |query|
    @query = query
    @threshold = threshold
    query[:time] < threshold
  end

  failure_message do |query|
    sql = query[:sql]
    plan = begin
      ActiveRecord::Base.connection.execute("EXPLAIN (ANALYZE, BUFFERS) #{sql}")
    rescue StandardError => e
      [["(Failed to EXPLAIN: #{e.message})"]]
    end

    pretty_plan = plan.respond_to?(:values) ? plan.values.map(&:first).join("\n") : plan.to_s

    <<~MSG
      Expected SQL query to complete in under #{@threshold} seconds, but took #{query[:time]}s.

      Query:

      #{sql}

      Query plan:

      #{pretty_plan}
    MSG
  end
end

RSpec::Matchers.define :be_fast_overall do |threshold: 0.2|
  description { "complete overall benchmark in under #{threshold}s" }

  match do |result|
    @result = result
    result.overall_time < threshold
  end

  failure_message do |result|
    filepath = "tmp/stackprof_#{RSpec.current_example.description.parameterize}.json"
    File.write(Rails.root.join(filepath), JSON.generate(result.profile))
    <<~MSG
      Expected overall time to be less than #{threshold}s, but was #{result.overall_time.round(3)}s.
      StackProf profile saved to: #{filepath}
      Open it at https://www.speedscope.app/
    MSG
  end
end
