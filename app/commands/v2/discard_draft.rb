module Commands
  module V2
    class DiscardDraft < BaseCommand
      def call
        validate_version_lock!
        raise_error_if_missing_draft!

        delete_access_limit

        if live
          update_draft_from_live
        else
          delete_draft
        end

        Success.new(content_id: content_id)
      end

    private
      def validate_version_lock!
        super(DraftContentItem, content_id, payload[:previous_version])
      end

      def raise_error_if_missing_draft!
        return if draft.present?

        code = live.present? ? 422 : 404
        message = "There is no draft content item to discard"

        raise CommandError.new(code: code, message: message)
      end

      def update_draft_from_live
        draft.update_attributes(live.attributes.except("id", "draft_content_item_id"))

        draft.increment_receipt_order

        if downstream
          ContentStoreWorker.perform_in(
            1.second,
            content_store: Adapters::DraftContentStore,
            live_content_item_id: live.id,
          )
        end
      end

      def delete_draft
        draft.destroy

        if downstream
          ContentStoreWorker.perform_in(
            1.second,
            content_store: Adapters::DraftContentStore,
            base_path: draft.base_path,
            delete: true,
          )
        end
      end

      def delete_access_limit
        AccessLimit.find_by(target: draft).try(:destroy)
      end

      def draft
        @draft ||= DraftContentItem.find_by(content_id: content_id, locale: locale)
      end

      def live
        @live ||= LiveContentItem.find_by(content_id: content_id, locale: locale)
      end

      def content_id
        payload[:content_id]
      end

      def locale
        payload[:locale] || DraftContentItem::DEFAULT_LOCALE
      end

      def update_type
        payload[:update_type]
      end
    end
  end
end
