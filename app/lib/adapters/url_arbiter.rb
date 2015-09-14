module Adapters
  class UrlArbiter
    attr_reader :url_arbiter

    def initialize(services: PublishingAPI)
      @url_arbiter = services.service(:url_arbiter)
    end

    def call(base_path, publishing_app)
      url_arbiter.reserve_path(
        base_path,
        publishing_app: publishing_app
      )
    rescue GOVUK::Client::Errors::BaseError => e
      if e.is_a?(GOVUK::Client::Errors::HTTPError) && [422, 409].include?(e.code)
        raise Command::Error.new(code: e.code, error_details: e.response)
      else
        raise Command::Error.new(code: 500, message: "Unexpected error whilst registering with url-arbiter: #{e}")
      end
    end
  end
end
