# Safely call out to content store and translate any http errors
# to
module Adapters
  class ContentStore
    attr_reader :live_content_store

    def initialize(services: PublishingAPI)
      @live_content_store = services.service(:live_content_store)
    end

    def call(base_path, content_item)
      live_content_store.put_content_item(
        base_path: base_path,
        content_item: content_item.except(:access_limited),
      )
    rescue GdsApi::HTTPServerError => e
      raise Command::Error.new(code: e.code, message: e.message)
    rescue GdsApi::HTTPClientError => e
      raise Command::Error.new(code: e.code, error_details: convert_error_details(e))
    rescue GdsApi::BaseError => e
      raise Command::Error.new(code: 500, message: "Unexpected error from content store: #{e.message}")
    end

  private
    def convert_error_details(upstream_error)
      {
        error: {
          code: upstream_error.code,
          fields: upstream_error.error_details.fetch('errors', {})
        }
      }
    end
  end
end
