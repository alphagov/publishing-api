source "https://rubygems.org"

gem "rails", "6.0.3.4"

gem "aws-sdk"
gem "bunny"
gem "colorize"
gem "dalli"
gem "diffy", require: false
gem "fuzzy_match"
gem "gds-api-adapters"
gem "gds-sso"
gem "govspeak"
gem "govuk_app_config"
gem "govuk_document_types"
gem "govuk_schemas"
gem "govuk_sidekiq"
gem "hashdiff"
gem "json-schema", require: false
gem "pg"
gem "plek"
# We can't use v5 of this because it requires redis 3 and we use 2.8
# We use our own fork because the latest 4.x release has a bug with
# removing jobs from the uniquejobs hash in redis
gem "sidekiq-unique-jobs", git: "https://github.com/alphagov/sidekiq-unique-jobs", branch: "fix-for-upstream-195-backported-to-4-x-branch", require: false
gem "whenever", require: false
gem "with_advisory_lock"

group :development do
  gem "listen"
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem "web-console"
end

gem "oj"

group :development, :test do
  gem "climate_control"
  gem "database_cleaner"
  gem "factory_bot_rails"
  gem "faker"
  gem "govuk-content-schema-test-helpers"
  gem "govuk_test"
  gem "pact"
  gem "pact_broker-client"
  gem "pry"
  gem "pry-byebug"
  gem "pry-rails"
  gem "rspec"
  gem "rspec-rails"
  gem "rubocop-govuk"
  gem "simplecov", require: false
  gem "spring"
  gem "spring-commands-rspec"
  gem "stackprof", require: false
  gem "timecop"
  gem "webmock", require: false
end
