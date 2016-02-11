module Queries
  module GetPublishIntent
    def self.call(base_path)
      response = content_store.get_publish_intent(base_path)
      response.to_hash.deep_symbolize_keys
    end

  private

    def self.content_store
      PublishingAPI.service(:live_content_store)
    end
  end
end
