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

# SidekiqUniqueJobs recommends not testing this behaviour https://github.com/mhenrixon/sidekiq-unique-jobs#uniqueness
SidekiqUniqueJobs.config.enabled = !Rails.env.test?
