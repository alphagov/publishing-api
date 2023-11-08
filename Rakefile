# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path("config/application", __dir__)

begin
  require "pact/tasks"
  require "pact_broker/client/tasks"

  PactBroker::Client::PublicationTask.new do |task|
    task.consumer_version = ENV.fetch("PACT_CONSUMER_VERSION")
    task.pact_broker_base_url = ENV.fetch("PACT_BROKER_BASE_URL")
    task.pact_broker_basic_auth = {
      username: ENV.fetch("PACT_BROKER_USERNAME"),
      password: ENV.fetch("PACT_BROKER_PASSWORD"),
    }
    task.pattern = ENV["PACT_PATTERN"] if ENV["PACT_PATTERN"]
  end
rescue LoadError
  # Pact isn't available in all environments
end

Rails.application.load_tasks

begin
  require "rubocop/rake_task"
  RuboCop::RakeTask.new
rescue LoadError
  # Rubocop isn't available in all environments
end

Rake::Task[:default].clear if Rake::Task.task_defined?(:default)
task default: %i[rubocop spec pact:verify]
