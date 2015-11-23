# Safely call out to content store and translate any http errors
# to
module Adapters
  class ContentStore
    def self.put_content_item(base_path, content_item)
      with_error_handling do
        PublishingAPI.service(:live_content_store).put_content_item(
          base_path: base_path,
          content_item: content_item.except(:access_limited),
        )
      end
    end

    def self.put_publish_intent(base_path, publish_intent)
      with_error_handling do
        PublishingAPI.service(:live_content_store).put_publish_intent(
          base_path: base_path,
          publish_intent: publish_intent,
        )
      end
    end

  private
    def self.with_error_handling(&block)
      block.call
    rescue GdsApi::HTTPServerError => e
      raise CommandError.new(code: e.code, message: e.message)
    rescue GdsApi::HTTPClientError => e
      raise CommandError.new(code: e.code, error_details: convert_error_details(e))
    rescue GdsApi::BaseError => e
      raise CommandError.new(code: 500, message: "Unexpected error from content store: #{e.message}")
    end

    def self.convert_error_details(upstream_error)
      {
        error: {
          code: upstream_error.code,
          message: upstream_error.message,
          fields: upstream_error.error_details.fetch('errors', {})
        }
      }
    end
  end
end
