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

# Use Sidekiq strict args to force Sidekiq 6 deprecations to error ahead of upgrade to Sidekiq 7
Sidekiq.strict_args!

# Logging for SidekiqUniqueJobs
# Somewhat copied from https://github.com/mhenrixon/sidekiq-unique-jobs/blob/36ffe8f95b01ab059a34c8093c2410a64ca191b9/UPGRADING.md?plain=1
SidekiqUniqueJobs.reflect do |on|
  on.duplicate do |job_hash|
    logger.warn(job_hash.merge(message: "Duplicate Job"))
  end

  on.execution_failed do |job_hash, exception = nil|
    message = "Execution failed"
    message += " (#{exception.message})" if exception
    logger.warn(job_hash.merge(message:))
  end

  on.lock_failed do |job_hash|
    logger.warn(job_hash.merge(message: "Lock failed to be acquired"))
  end

  on.reschedule_failed do |job_hash|
    logger.debug(job_hash.merge(message: "Reschedule failed"))
  end

  on.timeout do |job_hash|
    logger.warn(job_hash.merge(message: "Lock acquisition timed out"))
  end

  on.unknown_sidekiq_worker do |job_hash|
    logger.warn(job_hash.merge(message: "Unknown Sidekiq worker"))
  end

  on.unlock_failed do |job_hash|
    logger.warn(job_hash.merge(message: "Unlock failed"))
  end
end
