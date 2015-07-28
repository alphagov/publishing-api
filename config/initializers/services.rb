require "govuk/client/url_arbiter"

module PublishingAPI
  def self.register_service(name, service)
    @services ||= {}

    @services[name] = service
  end

  def self.services(name)
    @services[name] or raise ServiceNotRegisteredException.new(name)
  end

  class ServiceNotRegisteredException < Exception; end
end

PublishingAPI.register_service(:url_arbiter, GOVUK::Client::URLArbiter.new(Plek.new.find('url-arbiter')))
