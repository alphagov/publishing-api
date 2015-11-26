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

    def self.delete_content_item(base_path)
      CommandError.with_error_handling do
        PublishingAPI.service(:draft_content_store).delete_content_item(base_path)
      end
    end
  end
end
