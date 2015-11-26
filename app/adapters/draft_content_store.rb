module Adapters
  class DraftContentStore
    def self.put_content_item(base_path, content_item)
      CommandError.with_error_handling do
        PublishingAPI.service(:draft_content_store).put_content_item(
          base_path: base_path,
          content_item: content_item,
        )
      end
    end
  end
end
