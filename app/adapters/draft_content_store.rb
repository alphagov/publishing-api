module Adapters
  class DraftContentStore
    def self.call(base_path, content_item)
      PublishingAPI.service(:draft_content_store).put_content_item(
        base_path: base_path,
        content_item: content_item,
      )
    rescue GdsApi::HTTPServerError => e
      raise CommandError.new(code: e.code, message: e.message) unless should_suppress?(e)
    rescue GdsApi::HTTPClientError => e
      raise CommandError.new(code: e.code, error_details: e.error_details)
    rescue GdsApi::BaseError => e
      raise CommandError.new(code: 500, message: "Unexpected error from draft content store: #{e.message}")
    end

  private
    def self.should_suppress?(error)
      PublishingAPI.swallow_draft_connection_errors && error.code == 502
    end
  end
end
