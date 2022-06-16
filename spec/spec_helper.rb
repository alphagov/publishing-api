require "simplecov"
SimpleCov.start "rails"

# Opt-out of Pact sending analaytics data to their server
ENV["PACT_DO_NOT_TRACK"] = "true"

ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../config/environment", __dir__)
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?

require "rspec/rails"
require "pact/consumer/rspec"
require "webmock"
require "govuk_schemas"
require "sidekiq/testing"
require "sidekiq-unique-jobs"
require "sidekiq_unique_jobs/testing"

Sidekiq::Logging.logger = nil
# Sidekiq in test mode won't run server middleware by default.
Sidekiq::Testing.server_middleware do |chain|
  chain.add GovukSidekiq::APIHeaders::ServerMiddleware
end

Sidekiq.configure_client do |config|
  config.client_middleware do |chain|
    chain.remove SidekiqUniqueJobs::Middleware::Client
  end
end

if GovukSchemas::Schema.all.empty?
  raise <<-MESSAGE
    No schemas found

    The Publishing API tests require that the govuk-content-schemas
    are available. These are accessed through the GovukSchemas gem,
    which defaults to looking for the govuk-content-schemas repository
    at ../govuk-content-schemas and can be configured through the
    GOVUK_CONTENT_SCHEMAS_PATH environment variable.
  MESSAGE
end

Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |f| require f }

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    # This option will default to `true` in RSpec 4.
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    # This option will default to `true` in RSpec 4.
    mocks.verify_partial_doubles = true
  end

  config.disable_monkey_patching!
  config.expose_dsl_globally = false

  config.before(:suite) do
    WebMock.disable_net_connect!(allow_localhost: true)
  end

  config.infer_spec_type_from_file_location!
  config.example_status_persistence_file_path = "spec/examples.txt"

  config.include AuthenticationHelper::RequestMixin, type: :request
  config.include AuthenticationHelper::ControllerMixin, type: :controller

  config.after do
    Timecop.return
    GDS::SSO.test_user = nil
  end

  config.before(:suite) do
    Rails.application.load_tasks
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    if example.metadata[:skip_cleaning]
      example.run
    else
      DatabaseCleaner.cleaning { example.run }
    end
  end

  %i[controller request].each do |spec_type|
    config.before :each, type: spec_type do
      login_as_stub_user
    end
  end
end

Pact.service_consumer "Publishing API" do
  has_pact_with "Content Store" do
    mock_service :content_store do
      port 3093
    end
  end
end
