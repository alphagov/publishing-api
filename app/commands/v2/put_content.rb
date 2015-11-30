module Commands
  module V2
    class PutContent < BaseCommand
      def call
        validate_version_lock!

        content_item = create_or_update_draft_content_item!

        PathReservation.reserve_base_path!(base_path, content_item[:publishing_app])

        draft_payload = Presenters::ContentStorePresenter.present(content_item)
        ContentStoreWorker.perform_async(
          content_store: Adapters::DraftContentStore,
          base_path: base_path,
          payload: draft_payload,
        )

        response_hash = Presenters::Queries::ContentItemPresenter.present(content_item)
        Success.new(response_hash)
      end

    private
      def validate_version_lock!
        super(DraftContentItem, content_id, payload[:previous_version])
      end

      def content_id
        payload.fetch(:content_id)
      end

      def create_or_update_draft_content_item!
        DraftContentItem.create_or_replace(content_item_attributes) do |item|
          SubstitutionHelper.clear_draft!(item)

          item.assign_attributes_with_defaults(content_item_attributes)

          version = Version.find_or_initialize_by(target: item)
          version.increment
          version.save! if item.valid?
        end
      end

      def content_item_attributes
        payload.slice(*DraftContentItem::TOP_LEVEL_FIELDS)
      end
    end
  end
end
