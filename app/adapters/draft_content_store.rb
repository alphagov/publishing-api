module Adapters
  class DraftContentStore
    attr_reader :draft_content_store

    def initialize(services: PublishingAPI)
      @draft_content_store = services.service(:draft_content_store)
      @swallow_connection_errors = services.swallow_draft_connection_errors
    end

    def call(base_path, content_item)
      draft_content_store.put_content_item(
        base_path: base_path,
        content_item: content_item,
      )
    rescue GdsApi::HTTPServerError => e
      raise Command::Error.new(code: e.code, message: e.message) unless should_suppress?(e)
    rescue GdsApi::HTTPClientError => e
      raise Command::Error.new(code: e.code, error_details: e.error_details)
    rescue GdsApi::BaseError => e
      raise Command::Error.new(code: 500, message: "Unexpected error from draft content store: #{e.message}")
    end

    def should_suppress?(error)
      @swallow_connection_errors && error.code == 502
    end
  end
end
