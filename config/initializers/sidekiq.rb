SidekiqUniqueJobs.configure do |config|
  config.enabled = !Rails.env.test? # SidekiqUniqueJobs recommends not testing this behaviour https://github.com/mhenrixon/sidekiq-unique-jobs#uniqueness
  config.lock_ttl = 1.hour
end

Sidekiq.configure_client do |config|
  config.client_middleware do |chain|
    chain.add SidekiqLoggerMiddleware
    chain.add SidekiqUniqueJobs::Middleware::Client
  end
end

Sidekiq.configure_server do |config|
  config.client_middleware do |chain|
    chain.add SidekiqLoggerMiddleware
    chain.add SidekiqUniqueJobs::Middleware::Client
  end

  config.server_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Server
  end

  SidekiqUniqueJobs::Server.configure(config)
end

# Logging for SidekiqUniqueJobs
def extract_log_from_job(message, job_hash)
  {
    message: message,
    args: job_hash["args"],
    lock_args: job_hash["lock_args"],
    queue: job_hash["queue"],
    worker: job_hash["class"],
  }
end

SidekiqUniqueJobs.reflect do |on|
  on.duplicate do |job_hash|
    message = extract_log_from_job("Duplicate Job", job_hash)
    Sidekiq.logger.warn(message)
  end

  on.execution_failed do |job_hash, exception = nil|
    exception_message = "Execution failed"
    exception_message += " (#{exception.message})" if exception

    message = extract_log_from_job(exception_message, job_hash)
    Sidekiq.logger.warn(message)
  end

  on.lock_failed do |job_hash|
    message = extract_log_from_job("Lock failed to be acquired", job_hash)
    Sidekiq.logger.warn(message)
  end

  on.reschedule_failed do |job_hash|
    message = extract_log_from_job("Reschedule failed", job_hash)
    Sidekiq.logger.debug(message)
  end

  on.timeout do |job_hash|
    message = extract_log_from_job("Lock acquisition timed out", job_hash)
    Sidekiq.logger.warn(message)
  end

  on.unknown_sidekiq_worker do |job_hash|
    message = extract_log_from_job("Unknown Sidekiq worker", job_hash)
    Sidekiq.logger.warn(message)
  end

  on.unlock_failed do |job_hash|
    message = extract_log_from_job("Unlock failed", job_hash)
    Sidekiq.logger.warn(message)
  end
end
