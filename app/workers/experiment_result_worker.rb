class ExperimentResultWorker
  include Sidekiq::Worker
  include PerformAsyncInQueue

  sidekiq_options queue: :experiments

  LOCK_TIMEOUT = 60

  def perform(name, id, run_output, duration, type)
    type = type.to_sym

    Sidekiq.redis do |redis|
      this_branch = ExperimentResult.new(name, id, type, redis, run_output, duration)

      if this_branch.control?
        candidate = ExperimentResult.new(name, id, :candidate, redis)
        if candidate.available?
          this_branch.process_run_output(candidate)
        else
          self.class.perform_in(5.seconds, name, id, run_output, duration, type)
        end
      elsif this_branch.candidate?
        this_branch.store_run_output
      end
    end
  end
end
