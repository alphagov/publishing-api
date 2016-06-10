class ExperimentResultWorker
  include Sidekiq::Worker
  include PerformAsyncInQueue

  sidekiq_options queue: :experiments,
                  retry: 5

  LOCK_TIMEOUT = 60

  def perform(name, id, run_output, duration, type)
    Sidekiq.redis do |redis|
      this_branch = ExperimentResult.new(name, id, type, redis, run_output, duration)

      if this_branch.control?
        candidate = ExperimentResult.new(name, id, :candidate, redis)
        this_branch.process_run_output(candidate)
      elsif this_branch.candidate?
        this_branch.store_run_output
      end
    end
  end
end
