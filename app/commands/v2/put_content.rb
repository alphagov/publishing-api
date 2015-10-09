module Commands
  module V2
    class PutContent < BaseCommand
      def call
        create_or_update_draft_content_item!

        Adapters::UrlArbiter.call(base_path, content_item[:publishing_app])
        Adapters::DraftContentStore.call(base_path, draft_payload)
        Success.new(content_item)
      end

    private
      def content_item
        payload
      end

      def content_id
        content_item.fetch(:content_id)
      end

      def create_or_update_draft_content_item!
        DraftContentItem.create_or_replace(content_item_attributes)
      end

      def content_item_attributes
        content_item.slice(*DraftContentItem::TOP_LEVEL_FIELDS).merge(metadata: metadata)
      end

      def metadata
        content_item.except(*DraftContentItem::TOP_LEVEL_FIELDS)
      end

      def link_set
        @link_set ||= LinkSet.find_by(content_id: content_id)
      end

      def link_set_hash
        if link_set.present?
          {links: link_set.links}
        else
          {}
        end
      end

      def draft_payload
        content_item.merge(link_set_hash)
      end
    end
  end
end
