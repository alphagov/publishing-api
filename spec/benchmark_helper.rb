ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../config/environment", __dir__)

require "rspec/rails"

ActiveRecord::Base.establish_connection(:benchmark)

Dir[Rails.root.join("spec/benchmarks/support/**/*.rb")].sort.each { |f| require f }

RSpec.configure do |config|
  config.add_setting :benchmark_sql_log_dir, default: Rails.root.join("tmp/benchmarks/sql")
  config.add_setting :benchmark_profiles_dir, default: Rails.root.join("tmp/benchmarks/profiles")
  config.add_setting :benchmark_instrumentation_dir, default: Rails.root.join("tmp/benchmarks/instrumentation")

  config.before(:suite) do
    FileUtils.mkdir_p(config.benchmark_sql_log_dir)
    FileUtils.mkdir_p(config.benchmark_profiles_dir)
    FileUtils.mkdir_p(config.benchmark_instrumentation_dir)

    # Warm up ActiveRecord
    [Edition, Document, Link, Unpublishing].each(&:first)
  end

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
end
