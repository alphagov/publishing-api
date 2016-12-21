module Commands
  module V2
    class DiscardDraft < BaseCommand
      def call
        raise_error_if_missing_draft!

        check_version_and_raise_if_conflicting(draft, payload[:previous_version])

        delete_supporting_objects
        delete_draft_from_database
        increment_live_lock_version if live

        after_transaction_commit do
          downstream_discard_draft(draft.base_path, draft.content_id, locale)
        end

        Action.create_discard_draft_action(draft, locale, event)
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

      def downstream_discard_draft(path_used, content_id, locale)
        return unless downstream

        DownstreamDiscardDraftWorker.perform_async_in_queue(
          DownstreamDiscardDraftWorker::HIGH_QUEUE,
          base_path: path_used,
          content_id: content_id,
          locale: locale,
          payload_version: event.id,
          update_dependencies: true,
        )
      end

      def delete_supporting_objects
        Location.find_by(content_item: draft).try(:destroy)
        State.find_by(content_item: draft).try(:destroy)
        Translation.find_by(content_item: draft).try(:destroy)
        UserFacingVersion.find_by(content_item: draft).try(:destroy)
        LockVersion.find_by(target: draft).try(:destroy)
        AccessLimit.find_by(content_item: draft).try(:destroy)
        ChangeNote.where(content_item: draft).destroy_all
      end

      def increment_live_lock_version
        LockVersion.find_by!(target: live).increment!
      end

      def draft
        @draft ||= ContentItem.joins(:document).find_by(
          'documents.content_id': content_id,
          'documents.locale': locale,
          state: "draft",
        )
      end

      def live
        @live ||= ContentItem.joins(:document).find_by(
          'documents.content_id': content_id,
          'documents.locale': locale,
          state: %w(published unpublished),
        )
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
