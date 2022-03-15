require "clients/content_store_writer"
require "queue_publisher"
require "sidekiq_logger_middleware"

module PublishingAPI
  # To be set in dev mode so that this can run when the draft content store isn't running.
  cattr_accessor :swallow_connection_errors

  def self.register_service(name:, client:)
    @services ||= {}

    @services[name] = client
  end

  def self.service(name)
    @services[name] || raise(ServiceNotRegisteredException, name)
  end

  class ServiceNotRegisteredException < RuntimeError; end
end

PublishingAPI.register_service(
  name: :draft_content_store,
  client: ContentStoreWriter.new(
    Plek.find("draft-content-store"),
    bearer_token: ENV["DRAFT_CONTENT_STORE_BEARER_TOKEN"],
  ),
)

PublishingAPI.register_service(
  name: :live_content_store,
  client: ContentStoreWriter.new(
    Plek.find("content-store"),
    bearer_token: ENV["CONTENT_STORE_BEARER_TOKEN"],
  ),
)

rabbitmq_config = if ENV["DISABLE_QUEUE_PUBLISHER"] || (Rails.env.test? && ENV["ENABLE_QUEUE_IN_TEST_MODE"].blank?)
                    { noop: true }
                  elsif ENV["RABBITMQ_URL"] && ENV["RABBITMQ_EXCHANGE"]
                    { exchange: ENV["RABBITMQ_EXCHANGE"] }
                  else
                    Rails.application.config_for(:rabbitmq).symbolize_keys
                  end

PublishingAPI.register_service(
  name: :queue_publisher,
  client: QueuePublisher.new(rabbitmq_config),
)

if Rails.env.development?
  PublishingAPI.swallow_connection_errors = true
end

# Statsd "the process" listens on a port on the provided host for UDP
# messages. Given that it's UDP, it's fire-and-forget and will not
# block your application. You do not need to have a statsd process
# running locally on your development environment.
statsd_client = Statsd.new("localhost")
statsd_client.namespace = "govuk.app.publishing-api"
PublishingAPI.register_service(name: :statsd, client: statsd_client)
