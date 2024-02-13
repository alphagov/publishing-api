module Adapters
  class DraftContentStore
    def self.put_content_item(base_path, content_item)
      ci = ContentItem.find_or_create_by!(content_store: 'draft', base_path:)
      ci.update!(content_item)
    end

    def self.delete_content_item(base_path)
      ci = ContentItem.draft.find_by(base_path:)
      ci.delete!
    end
  end
end
