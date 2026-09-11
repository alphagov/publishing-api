return if Rails.env.production?

require "pact_broker/client/tasks"

PactBroker::Client::PublicationTask.new("branch") do |task|
  task.consumer_version = ENV.fetch("PACT_TARGET_BRANCH")
  task.pact_broker_base_url = ENV.fetch("PACT_BROKER_BASE_URL")

  if ENV["PACT_BROKER_USERNAME"]
    task.pact_broker_basic_auth = {
      username: ENV["PACT_BROKER_USERNAME"],
      password: ENV["PACT_BROKER_PASSWORD"],
    }
  end
end

require "rspec/core/rake_task"

desc "Verify the GDS API Adapters pacts against this application"
RSpec::Core::RakeTask.new("pact:verify_v2") do |task|
  task.pattern = "spec/pact/consumers/**/*_spec.rb"
  task.rspec_opts = "--tag pact_v2"
end
