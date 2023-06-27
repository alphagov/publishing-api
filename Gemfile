source "https://rubygems.org"

gem "rails", "7.0.5.1"

gem "aws-sdk-s3"
gem "bootsnap", require: false
gem "bunny"
gem "dalli"
gem "fuzzy_match"
gem "gds-api-adapters"
gem "gds-sso"
gem "govspeak"
gem "govuk_app_config"
gem "govuk_document_types"
gem "govuk_schemas"
gem "govuk_sidekiq"
gem "jsonnet", "~>0.4.0" #  0.5 (current latest) does not currently compile on our CI machines
gem "json-schema", require: false
gem "oj"
gem "pg"
gem "plek"
gem "sentry-sidekiq"
gem "sidekiq-unique-jobs"
gem "whenever", require: false
gem "with_advisory_lock"

group :development do
  gem "listen"
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem "web-console"
end

group :development, :test do
  gem "byebug"
  gem "climate_control"
  gem "database_cleaner"
  gem "factory_bot_rails"
  gem "govuk_test"
  gem "pact", require: false
  gem "pact_broker-client", require: false
  gem "rspec-rails"
  gem "rubocop-govuk", require: false
  gem "simplecov", require: false
  gem "timecop"
  gem "webmock", require: false
end
