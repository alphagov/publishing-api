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

    require 'pact/tasks/task_helper'

    with_temporary_env('GDS_API_PACT_VERSION', "branch-#{args[:branch_name]}") do
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
end
