unless Rails.env.production?

  desc "Verifies the pact files for latest release and master"
  task "pact:verify" do
    require 'pact/tasks/task_helper'

    Pact::TaskHelper.handle_verification_failure do
      Pact::TaskHelper.execute_pact_verify
    end

    unless ENV['USE_LOCAL_PACT'] # avoid running twice against the same pact file.
      with_temporary_env('GDS_API_PACT_VERSION', "master") do
        Pact::TaskHelper.handle_verification_failure do
          Pact::TaskHelper.execute_pact_verify
        end
      end
    end
  end

  task :default => "pact:verify"

  task "pact:verify:branch", [:branch_name] do |t, args|
    abort "Please provide a branch name. eg rake #{t.name}[my_feature_branch]" unless args[:branch_name]

    pact_version = args[:branch_name] == "master" ? args[:branch_name] : "branch-#{args[:branch_name]}"

    require 'pact/tasks/task_helper'

    with_temporary_env('GDS_API_PACT_VERSION', pact_version) do
      Pact::TaskHelper.handle_verification_failure do
        Pact::TaskHelper.execute_pact_verify
      end
    end
  end

  def with_temporary_env(key, value)
    original_value = ENV[key]
    ENV[key] = value
    yield
  ensure
    ENV[key] = original_value
  end

  require 'pact_broker/client/tasks'

  def configure_pact_broker_location(task)
    task.pact_broker_base_url = ENV.fetch("PACT_BROKER_BASE_URL")

    if ENV['PACT_BROKER_USERNAME']
      task.pact_broker_basic_auth = {
        username: ENV['PACT_BROKER_USERNAME'],
        password: ENV['PACT_BROKER_PASSWORD']
      }
    end
  end

  PactBroker::Client::PublicationTask.new("branch") do |task|
    task.consumer_version = ENV.fetch("PACT_TARGET_BRANCH")
    configure_pact_broker_location(task)
  end
end
