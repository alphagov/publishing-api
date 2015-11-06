redis_config = {
  host: ENV["REDIS_HOST"] || "127.0.0.1",
  port: ENV["REDIS_PORT"] || 6379,
  namespace: "publishing_api",
}

Sidekiq.configure_server do |config|
  config.redis = redis_config
  config.error_handlers << Proc.new {|ex, context_hash| Airbrake.notify(ex, context_hash) }

  config.server_middleware do |chain|
    chain.add Sidekiq::Statsd::ServerMiddleware, env: 'govuk.app.publishing-api', prefix: 'workers'
  end
end

Sidekiq.configure_client do |config|
  config.redis = redis_config
end

require 'sidekiq/logging/json'
Sidekiq.logger.formatter = Sidekiq::Logging::Json::Logger.new
