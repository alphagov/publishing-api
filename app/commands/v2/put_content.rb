module Commands
  module V2
    class PutContent < BaseCommand
      def call
        content_item = create_or_update_draft_content_item!

        Adapters::UrlArbiter.call(base_path, payload[:publishing_app])
        Adapters::DraftContentStore.call(base_path, draft_payload(content_item))
        Success.new(payload)
      rescue ActiveRecord::RecordInvalid => e
        raise_command_error(e)
      end

    private
      def content_id
        payload.fetch(:content_id)
      end

      def create_or_update_draft_content_item!
        DraftContentItem.create_or_replace(content_item_attributes) do |item|
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

      def raise_command_error(e)
        errors = e.record.errors
        full_message = errors.full_messages.join

        raise CommandError.new(
          code: 422,
          message: full_message,
          error_details: {
            error: {
              code: 422,
              message: full_message,
              fields: errors.to_hash
            }
          }
        )
      end
    end
  end
end
