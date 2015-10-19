source "https://rubygems.org"

# Bundle edge Rails instead: gem "rails", github: "rails/rails"
gem "rails", "4.2.4"
# Use SCSS for stylesheets
gem "sass-rails", "~> 5.0"
# Use Uglifier as compressor for JavaScript assets
gem "uglifier", ">= 1.3.0"

gem "unicorn", "~> 4.9.0"
gem "logstasher", "0.6.2"
gem "plek", "~> 1.10"
gem "airbrake", "~> 4.2.1"
gem "pg"

gem "govuk-client-url_arbiter", "0.0.3"
gem "gds-api-adapters", "22.0.0"

gem 'bunny', '2.0.0'
gem 'whenever', '0.9.4', :require => false
gem "sidekiq", "3.5.1"
gem "sidekiq-logging-json", "0.0.14"

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem "web-console", "~> 2.0"
end

group :development, :test do
  # Call "byebug" anywhere in the code to stop execution and get a debugger console
  gem "byebug"
  gem "pact"
  gem "database_cleaner"
  gem "webmock", require: false
  gem "timecop"
  gem "rspec"
  gem "rspec-rails", "~> 3.3"
  gem "simplecov", "0.10.0", require: false
  gem "simplecov-rcov", "0.2.3", require: false
  gem "factory_girl_rails", "4.5.0"
end
