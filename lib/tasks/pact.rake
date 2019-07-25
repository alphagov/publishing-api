return if Rails.env.production?

require 'pact/tasks'
require 'pact_broker/client/tasks'
require 'pact/tasks/task_helper'

task "pact:verify:branch", [:branch_name] do |t, args|
  abort "Please provide a branch name. eg rake #{t.name}[my_feature_branch]" unless args[:branch_name]

  pact_version = args[:branch_name] == "master" ? args[:branch_name] : "branch-#{args[:branch_name]}"

  ClimateControl.modify(GDS_API_PACT_VERSION: pact_version) do
    Pact::TaskHelper.handle_verification_failure do
      Pact::TaskHelper.execute_pact_verify
    end
  end
end

PactBroker::Client::PublicationTask.new("branch") do |task|
  task.consumer_version = ENV.fetch("PACT_TARGET_BRANCH")
  task.pact_broker_base_url = ENV.fetch("PACT_BROKER_BASE_URL")

  if ENV['PACT_BROKER_USERNAME']
    task.pact_broker_basic_auth = {
      username: ENV['PACT_BROKER_USERNAME'],
      password: ENV['PACT_BROKER_PASSWORD']
    }
  end
end
