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
  gem 'gds-api-adapters', "~> 53.1.0"
end

gem "gds-sso", "~> 13.6"
gem "govuk_app_config", "~> 1.8"
gem "govuk_document_types", "~> 0.7.1"
gem "govuk_schemas", "~> 3.2"
gem "govuk_sidekiq", "~> 3.0"

gem "aws-sdk", "~> 3"
gem 'bunny', '~> 2.11'
gem "diffy", "~> 3.2", require: false
gem "govspeak", "~> 5.6.0"
gem "hashdiff", "~> 0.3.6"
gem "json-schema", require: false
# We can't use v5 of this because it requires redis 3 and we use 2.8
# We use our own fork because the latest 4.x release has a bug with
# removing jobs from the uniquejobs hash in redis
gem "sidekiq-unique-jobs", git: "https://github.com/alphagov/sidekiq-unique-jobs", branch: "fix-for-upstream-195-backported-to-4-x-branch", require: false
gem 'whenever', '0.10.0', require: false
gem "with_advisory_lock", "~> 4.0"

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
  gem "factory_bot_rails", "~> 4.11"
  gem "faker"
  gem 'govuk-content-schema-test-helpers', "~> 1.6"
  gem "govuk-lint"
  gem "pact"
  gem "pact_broker-client"
  gem "pry"
  gem "pry-byebug"
  gem "pry-rails"
  gem "rspec"
  gem "rspec-rails", "~> 3.8"
  gem "simplecov", "0.16.1", require: false
  gem "simplecov-rcov", "0.2.3", require: false
  gem "spring"
  gem "spring-commands-rspec"
  gem "stackprof", require: false
  gem "timecop"
  gem "webmock", require: false
end
