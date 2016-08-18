source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails"
gem "rails", "4.2.7.1"

gem "unicorn", "~> 4.9.0"
gem "logstasher", "0.6.2"
gem "plek", "~> 1.10"
gem "airbrake", "~> 4.2.1"
gem "pg"

if ENV["API_DEV"]
  gem "gds-api-adapters", path: "../gds-api-adapters"
else
  gem "gds-api-adapters", "33.0.0"
end

gem "gds-sso", "12.1.0"

gem 'bunny', '2.5.1'
gem 'whenever', '0.9.4', require: false
gem "govuk_sidekiq", "~> 0.0"
gem "deprecated_columns"
gem "json-schema", require: false
gem "hashdiff"
gem "sidekiq-unique-jobs", require: false

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
  gem "rspec-rails", "~> 3.3"
  gem "simplecov", "0.10.0", require: false
  gem "simplecov-rcov", "0.2.3", require: false
  gem "factory_girl_rails", "4.5.0"
  gem "pact_broker-client"
  gem "govuk-lint"
  gem "faker"
  gem "stackprof", require: false
  gem "spring"
  gem "spring-commands-rspec"
end
