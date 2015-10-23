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

  def with_temporary_env(key, value)
    original_value = ENV[key]
    ENV[key] = value
    yield
  ensure
    ENV[key] = original_value
  end
end
