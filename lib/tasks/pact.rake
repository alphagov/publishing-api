require 'pact/tasks'

# defines the task "pact:verify:master"
Pact::VerificationTask.new("master") do | pact |
  pact.uri "https://pactcontract:#{ENV['PACT_CI_API_KEY']}@ci-new.alphagov.co.uk/job/govuk_gds_api_adapters/lastSuccessfulBuild/artifact/spec/pacts/gds_api_adapters-publishing_api.json"
end

# This is just to generate a friendly warning message if the PACT_CI_API_KEY env var is not set
task :require_pact_ci_api_key do
  unless ENV['PACT_CI_API_KEY']
    raise "Environment variable 'PACT_CI_API_KEY' required. See https://ci-new.alphagov.co.uk/user/pactcontract/configure"
  end
end

task "pact:verify:master" => :require_pact_ci_api_key
