module Candidates
  class BaseCandidate
    include Sidekiq::Worker
    include PerformAsyncInQueue

    sidekiq_options queue: :experiments

    def experiment_candidate(experiment)
      experiment.symbolize_keys!

      start_time = Time.now
      result = yield
      duration = (Time.now - start_time).to_f

      ExperimentResultWorker.perform_async(experiment[:name], experiment[:id], result, duration, :candidate)

      result
    rescue StandardError => exception
      if ENV["RAISE_EXPERIMENT_ERRORS"]
        raise exception
      else
        backtrace = exception.backtrace
        backtrace.unshift(exception.inspect)
        ExperimentErrorWorker.perform_async(experiment[:name], experiment[:id], backtrace.join("\n"))
      end
    end
  end
end
