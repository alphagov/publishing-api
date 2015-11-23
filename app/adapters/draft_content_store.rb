module Adapters
  class DraftContentStore
    def self.put_content_item(base_path, content_item)
      PublishingAPI.service(:draft_content_store).put_content_item(
        base_path: base_path,
        content_item: content_item,
      )
    rescue GdsApi::HTTPServerError => e
      raise CommandError.new(code: e.code, message: e.message) unless should_suppress?(e)
    rescue GdsApi::HTTPClientError => e
      raise CommandError.new(code: e.code, error_details: convert_error_details(e))
    rescue GdsApi::BaseError => e
      raise CommandError.new(code: 500, message: "Unexpected error from draft content store: #{e.message}")
    end

  private
    def self.should_suppress?(error)
      PublishingAPI.swallow_draft_connection_errors && error.code == 502
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
