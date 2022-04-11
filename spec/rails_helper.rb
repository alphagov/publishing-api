require "simplecov"
SimpleCov.start "rails"

# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= "test"
require File.expand_path("../config/environment", __dir__)
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "spec_helper"
require "database_cleaner"
require "rspec/rails"
# Add additional requires below this line. Rails is not loaded until this point!
require "sidekiq/testing"
require "sidekiq_unique_jobs/testing"
Sidekiq::Logging.logger = nil
# Sidekiq in test mode won't run server middleware by default.
Sidekiq::Testing.server_middleware do |chain|
  chain.add GovukSidekiq::APIHeaders::ServerMiddleware
end

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |f| require f }

require "sidekiq-unique-jobs"
Sidekiq.configure_client do |config|
  config.client_middleware do |chain|
    chain.remove SidekiqUniqueJobs::Middleware::Client
  end
end

RSpec.configure do |config|
  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
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
