Sidekiq.configure_client do |config|
  config.client_middleware do |chain|
    chain.add SidekiqLoggerMiddleware
  end
end

Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add SidekiqWorkerLoggerMiddleware
  end
end
