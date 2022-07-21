# Safely call out to content store and translate any http errors
# to
module Adapters
  class ContentStore
    def self.put_content_item(base_path, content_item)
      CommandError.with_error_handling do
        PublishingAPI.service(:live_content_store).put_content_item(
          base_path: base_path,
          content_item: content_item,
        )
      end
    end

    def self.put_publish_intent(base_path, publish_intent)
      CommandError.with_error_handling do
        PublishingAPI.service(:live_content_store).put_publish_intent(
          base_path: base_path,
          publish_intent: publish_intent,
        )
      end
    end

    def self.delete_content_item(base_path)
      CommandError.with_error_handling(ignore_404s: true) do
        PublishingAPI.service(:live_content_store).delete_content_item(base_path)
      end
    end
  end
end
