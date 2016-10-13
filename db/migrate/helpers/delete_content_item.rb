module Helpers
  module DeleteContentItem
    def self.destroy_content_items_with_links(content_ids)
      ::Services::DeleteContentItem.
        destroy_content_items_with_links(content_ids)
    end
  end
end
