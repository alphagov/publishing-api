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
  client: ContentStoreWriter.new(Plek.find('live-content-store'))
)
