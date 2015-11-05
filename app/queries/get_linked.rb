module Queries
  module GetLinked
    def self.call(content_id, link_type)
      content_item_links = ContentItemLink.where(target: content_id, link_type: link_type)

      if content_item_links.empty?
        error_details = {
          error: {
            code: 404,
            message: "Could not find any item with a link of type '#{link_type}' linked to this item: '#{content_id}'"
          }
        }

        raise CommandError.new(code: 404, error_details: error_details)
      else
        content_item_links
      end
    end
  end
end
