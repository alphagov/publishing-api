source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails"
gem "arel", "~> 9"
gem "rails", "~> 5"

gem "colorize", "~> 0.8"
gem "dalli"
gem "pg", "~> 1.2.2"
gem "plek", "~> 3.0"


if ENV["API_DEV"]
  gem "gds-api-adapters", path: "../gds-api-adapters"
else
  gem "gds-api-adapters", "~> 63"
end

gem "gds-sso", "~> 14.2"
gem "govuk_app_config", "~> 2.0"
gem "govuk_document_types", "~> 0.9.2"
gem "govuk_schemas", "~> 4.0"
gem "govuk_sidekiq", "~> 3.0"

gem "aws-sdk", "~> 3"
gem "bunny", "~> 2.14"
gem "diffy", "~> 3.3", require: false
gem "fuzzy_match", "~> 2.1"
gem "govspeak", "~> 6.5.2"
gem "hashdiff", "~> 1.0.0"
gem "json-schema", require: false
# We can't use v5 of this because it requires redis 3 and we use 2.8
# We use our own fork because the latest 4.x release has a bug with
# removing jobs from the uniquejobs hash in redis
gem "sidekiq-unique-jobs", git: "https://github.com/alphagov/sidekiq-unique-jobs", branch: "fix-for-upstream-195-backported-to-4-x-branch", require: false
gem "whenever", "1.0.0", require: false
gem "with_advisory_lock", "~> 4.6"

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem "web-console", "~> 3"
end

gem "oj", "~> 3.10"

group :development, :test do
  gem "climate_control", "~> 0.2"
  gem "database_cleaner"
  gem "factory_bot_rails", "~> 5.1"
  gem "faker"
  gem "govuk-content-schema-test-helpers", "~> 1.6"
  gem "govuk_test", "~> 1.0"
  gem "pact"
  gem "pact_broker-client"
  gem "pry"
  gem "pry-byebug"
  gem "pry-rails"
  gem "rspec"
  gem "rspec-rails", "~> 3.9"
  gem "rubocop-govuk"
  gem "simplecov", "0.17.1", require: false
  gem "spring"
  gem "spring-commands-rspec"
  gem "stackprof", require: false
  gem "timecop"
  gem "webmock", require: false
end
