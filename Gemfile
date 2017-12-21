source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails"
gem "rails", "5.1"
gem "arel", "8.0"

gem "unicorn", "~> 5.3.1"
gem "logstasher", "1.2.2"
gem "plek", "~> 2.0"
gem "pg"
gem 'dalli'

gem "colorize", "~> 0.8"

if ENV["API_DEV"]
  gem "gds-api-adapters", path: "../gds-api-adapters"
else
  gem 'gds-api-adapters', "~> 50.7.0"
end

gem "gds-sso", "13.5.0"
gem "govuk_app_config", "~> 0.2"
gem "govuk_schemas", "~> 3.1.0"
gem "govuk_document_types", "~> 0.2"

gem 'bunny', '~> 2.8'
gem "govuk_sidekiq", "~> 2.0"
gem 'whenever', '0.10.0', require: false
gem "json-schema", require: false
gem "hashdiff", "~> 0.3.6"
gem "sidekiq-unique-jobs", "~> 5.0", require: false
gem "govspeak", "~> 5.2.2"
gem "diffy", "~> 3.1", require: false
gem "aws-sdk", "~> 3"
gem "with_advisory_lock", "~> 3.1"

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem "web-console", "~> 3"
end

gem "oj", "~> 2.16.1"
gem "oj_mimic_json", "~> 1.0.1"

group :development, :test do
  gem "pry"
  gem "pry-byebug"
  gem "pry-rails"
  gem "pact"
  gem "database_cleaner"
  gem "webmock", require: false
  gem "timecop"
  gem "rspec"
  gem "rspec-rails", "~> 3.5"
  gem "simplecov", "0.15.1", require: false
  gem "simplecov-rcov", "0.2.3", require: false
  gem "factory_girl_rails", "4.9.0"
  gem "pact_broker-client"
  gem "govuk-lint"
  gem "faker"
  gem "stackprof", require: false
  gem "spring"
  gem "spring-commands-rspec"
end
