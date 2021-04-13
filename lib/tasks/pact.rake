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
