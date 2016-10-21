source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails"
gem "rails", "5.0.0.1"
gem "arel", "7.1.4"

gem "unicorn", "~> 4.9.0"
gem "logstasher", "0.6.2"
gem "plek", "~> 1.10"
gem 'airbrake', '~> 5.5'
gem 'airbrake-ruby', '1.5'
gem "pg"
gem 'dalli'

if ENV["API_DEV"]
  gem "gds-api-adapters", path: "../gds-api-adapters"
else
  gem "gds-api-adapters", "36.3.0"
end

gem "gds-sso", "13.0.0"
gem "govuk_schemas", "~> 1.0"

gem 'bunny', '2.5.1'
gem 'whenever', '0.9.4', require: false
gem "govuk_sidekiq", "~> 1.0.1"
gem "json-schema", require: false
gem "hashdiff"
gem "sidekiq-unique-jobs", require: false
gem "govspeak", "~> 5.0.2"
gem "diffy", "~> 3.1", require: false
gem "aws-sdk", "~> 2"

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem "web-console", "~> 2.0"
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
  gem "simplecov", "0.10.0", require: false
  gem "simplecov-rcov", "0.2.3", require: false
  gem "factory_girl_rails", "4.7.0"
  gem "pact_broker-client"
  gem "govuk-lint"
  gem "faker"
  gem "stackprof", require: false
  gem "spring"
  gem "spring-commands-rspec"
end
