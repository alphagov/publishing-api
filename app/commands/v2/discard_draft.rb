module Commands
  module V2
    class DiscardDraft < BaseCommand
      def call
        raise_error_if_missing_draft!

        check_version_and_raise_if_conflicting(draft, payload[:previous_version])

        draft_path = Location.find_by!(content_item: draft).base_path

        delete_supporting_objects
        delete_draft_from_database
        increment_live_lock_version if live

        after_transaction_commit do
          delete_draft_from_draft_content_store(draft_path)
          send_live_to_draft_content_store(live)
        end

        Success.new(content_id: content_id)
      end

    private

      def raise_error_if_missing_draft!
        return if draft.present?

        code = live.present? ? 422 : 404
        message = "There is no draft content item to discard"

        raise CommandError.new(code: code, message: message)
      end

      def delete_draft_from_database
        draft.destroy
      end

      def delete_draft_from_draft_content_store(draft_path)
        return unless downstream

        PresentedContentStoreWorker.perform_async(
          content_store: Adapters::DraftContentStore,
          base_path: draft_path,
          delete: true,
          request_uuid: GdsApi::GovukHeaders.headers[:govuk_request_id],
        )
      end

      def send_live_to_draft_content_store(live)
        return unless downstream
        return unless live

        PresentedContentStoreWorker.perform_async(
          content_store: Adapters::DraftContentStore,
          payload: { content_item_id: live.id, payload_version: event.id },
          request_uuid: GdsApi::GovukHeaders.headers[:govuk_request_id],
        )
      end

      def delete_supporting_objects
        State.find_by(content_item: draft).try(:destroy)
        Translation.find_by(content_item: draft).try(:destroy)
        Location.find_by(content_item: draft).try(:destroy)
        UserFacingVersion.find_by(content_item: draft).try(:destroy)
        LockVersion.find_by(target: draft).try(:destroy)
        AccessLimit.find_by(content_item: draft).try(:destroy)
      end

      def increment_live_lock_version
        lock_version = LockVersion.find_by!(target: live)
        lock_version.increment
        lock_version.save!
      end

      def draft
        @draft ||= ContentItemFilter.new(scope: ContentItem.where(content_id: content_id)).filter(
          locale: locale,
          state: "draft",
        ).first
      end

      def live
        @live ||= ContentItemFilter.new(scope: ContentItem.where(content_id: content_id)).filter(
          locale: locale,
          state: "published",
        ).first
      end

      def content_id
        payload[:content_id]
      end

      def locale
        payload[:locale] || ContentItem::DEFAULT_LOCALE
      end
    end
  end
end
