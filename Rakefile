# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

require 'pact/tasks'

Rails.application.load_tasks

Pact::VerificationTask.new("master") do | pact |
  pact.uri "https://pactcontract:#{ENV['PACT_CI_API_KEY']}@ci-new.alphagov.co.uk/job/govuk_gds_api_adapters/lastSuccessfulBuild/artifact/spec/pacts/gds_api_adapters-publishing_api.json"
end

task :require_pact_ci_api_key do
  unless ENV['PACT_CI_API_KEY']
    raise "Environment variable 'PACT_CI_API_KEY' required. See https://ci-new.alphagov.co.uk/user/pactcontract/configure"
  end
end

task "pact:verify:master" => :require_pact_ci_api_key
