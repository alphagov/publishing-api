module Commands
  module V2
    class PutContent < BaseCommand
      def call
        content_item = create_or_update_draft_content_item!

        PathReservation.reserve_base_path!(base_path, content_item[:publishing_app])
        Adapters::UrlArbiter.call(base_path, payload[:publishing_app])
        Adapters::DraftContentStore.call(base_path, draft_payload(content_item))
        Success.new(payload)
      end

    private
      def content_id
        payload.fetch(:content_id)
      end

      def create_or_update_draft_content_item!
        DraftContentItem.create_or_replace(content_item_attributes) do |item|
          version = Version.find_or_initialize_by(target: item)
          version.increment
          version.save!

          item.assign_attributes_with_defaults(content_item_attributes)
        end
      end

      def content_item_attributes
        payload
          .slice(*DraftContentItem::TOP_LEVEL_FIELDS)
          .merge(metadata: metadata)
          .except(:version)
      end

      def metadata
        payload.except(*DraftContentItem::TOP_LEVEL_FIELDS)
      end

      def draft_payload(content_item)
        draft_item_hash = LinkSetMerger.merge_links_into(content_item)
        Presenters::ContentItemPresenter.present(draft_item_hash)
      end
    end
  end
end
