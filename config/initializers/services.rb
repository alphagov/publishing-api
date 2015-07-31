require "govuk/client/url_arbiter"

module PublishingAPI
  def self.register_service(name:, client:)
    @services ||= {}

    @services[name] = client
  end

  def self.services(name)
    @services[name] or raise ServiceNotRegisteredException.new(name)
  end

  class ServiceNotRegisteredException < Exception; end
end

PublishingAPI.register_service(
  name: :url_arbiter,
  client: GOVUK::Client::URLArbiter.new(Plek.find('url-arbiter'))
)

PublishingAPI.register_service(
  name: :draft_content_store,
  client: ContentStoreWriter.new(Plek.find('draft-content-store'))
)

PublishingAPI.register_service(
  name: :live_content_store,
  client: ContentStoreWriter.new(Plek.find('content-store'))
)

if ENV['DISABLE_QUEUE_PUBLISHER'] || (Rails.env.test? && ENV['ENABLE_QUEUE_IN_TEST_MODE'].blank?)
  rabbitmq_config = {noop: true}
else
  rabbitmq_config = YAML.load_file(Rails.root.join("config", "rabbitmq.yml"))[Rails.env].symbolize_keys
end

PublishingAPI.register_service(
  name: :queue_publisher,
  client: QueuePublisher.new(rabbitmq_config)
)
