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

desc "Verify the consumer pacts against this application"
RSpec::Core::RakeTask.new("pact:provider_v2") do |task|
  task.pattern = "spec/pact/consumers/**/*_spec.rb"
  task.rspec_opts = "--tag pact_v2"
end

desc "Verify the provider pacts against this application"
RSpec::Core::RakeTask.new("pact:consumer_v2") do |task|
  task.pattern = "spec/pact/providers/**/*_spec.rb"
  task.rspec_opts = "--tag pact_v2"
end

Rake::Task["pact:consumer_v2"].enhance do
  dir = ENV.fetch("PACT_V2_PACT_DIR", "spec/pacts")
  generated = File.join(dir, "Publishing API-Content Store.json")
  v1_filename = File.join(dir, "publishing_api-content_store.json")

  File.rename(generated, v1_filename) if File.exist?(generated)
end

desc "Verify the consumer and provider pacts against this application"
task "pact:verify_v2" => %w[pact:provider_v2 pact:consumer_v2]
