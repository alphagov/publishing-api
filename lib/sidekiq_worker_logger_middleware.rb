class SidekiqWorkerLoggerMiddleware
  def call(worker_class, job, queue)
    begin
      logger.info "Worker #{worker_class} picked up job #{job['jid']} from queue #{queue} with arguments #{job['args'].try(:first)}"
      yield
    rescue => ex
      logger.error ex.message
      raise
    end
  end
end
