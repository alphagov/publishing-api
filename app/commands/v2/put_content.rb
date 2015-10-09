module Commands
  module V2
    class PutContent < BaseCommand
      def call
        create_or_update_draft_content_item!

        Adapters::UrlArbiter.new.call(base_path, content_item[:publishing_app])
        Adapters::DraftContentStore.new.call(base_path, content_item)
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
        content_item.slice(*content_item_top_level_fields).merge(metadata: metadata)
      end

      def metadata
        content_item.except(*content_item_top_level_fields)
      end

      def content_item_top_level_fields
        %I(
          access_limited
          base_path
          content_id
          description
          details
          format
          locale
          public_updated_at
          publishing_app
          redirects
          rendering_app
          routes
          title
        )
      end
    end
  end
end
