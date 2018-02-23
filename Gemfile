source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails"
gem "arel", "8.0"
gem "rails", "5.1"

gem "colorize", "~> 0.8"
gem 'dalli'
gem "pg", "~> 0.21.0"
gem "plek", "~> 2.1"


if ENV["API_DEV"]
  gem "gds-api-adapters", path: "../gds-api-adapters"
else
  gem 'gds-api-adapters', "~> 51.2.0"
end

gem "gds-sso", "~> 13.6"
gem "govuk_app_config", "~> 1.3"
gem "govuk_document_types", "~> 0.2"
gem "govuk_schemas", "~> 3.1"
gem "govuk_sidekiq", "~> 3.0"

gem "aws-sdk", "~> 3"
gem 'bunny', '~> 2.9'
gem "diffy", "~> 3.1", require: false
gem "foreman", "~> 0.84.0"
gem "govspeak", "~> 5.5.0"
gem "hashdiff", "~> 0.3.6"
gem "json-schema", require: false
gem "sidekiq-unique-jobs", "~> 5.0", require: false
gem 'whenever', '0.10.0', require: false
gem "with_advisory_lock", "~> 3.1"

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem "web-console", "~> 3"
end

# Lock to 2.18.3 because later patch versions are not listed in the oj changelog
# and cause test failures.
gem "oj", "2.18.3"
gem "oj_mimic_json", "~> 1.0.1"

group :development, :test do
  gem "database_cleaner"
  gem "factory_bot_rails", "~> 4.8"
  gem "faker"
  gem 'govuk-content-schema-test-helpers', "~> 1.6"
  gem "govuk-lint"
  gem "pact"
  gem "pact_broker-client"
  gem "pry"
  gem "pry-byebug"
  gem "pry-rails"
  gem "rspec"
  gem "rspec-rails", "~> 3.5"
  gem "simplecov", "0.15.1", require: false
  gem "simplecov-rcov", "0.2.3", require: false
  gem "spring"
  gem "spring-commands-rspec"
  gem "stackprof", require: false
  gem "timecop"
  gem "webmock", require: false
end
