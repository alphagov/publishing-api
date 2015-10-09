module Commands
  module V2
    class PutContent < BaseCommand
      def call
        create_or_update_draft_content_item!

        Adapters::UrlArbiter.call(base_path, content_item[:publishing_app])
        Adapters::DraftContentStore.call(base_path, content_item)
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
    end
  end
end
