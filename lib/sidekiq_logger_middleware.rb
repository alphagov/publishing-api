class SidekiqLoggerMiddleware
  def call(worker_class, job, queue, _redis_pool)
    logger.info "Enqueuing #{worker_class} to queue: #{queue} with job id: #{job['jid']} and arguments: #{job['args'].try(:first)}"
    yield
  end
end
