module Commands
  module V2
    class DiscardDraft < BaseCommand
      def call
        raise_error_if_missing_draft!

        check_version_and_raise_if_conflicting(document, payload[:previous_version])

        delete_supporting_objects(document.draft)
        delete_draft_from_database
        increment_lock_version

        after_transaction_commit do
          downstream_discard_draft(
            document.draft.base_path,
            document.content_id,
            document.locale
          )
        end

        Action.create_discard_draft_action(document.draft, document.locale, event)
        Success.new(content_id: document.content_id)
      end

    private

      def raise_error_if_missing_draft!
        return if document.draft.present?

        code = document.published_or_unpublished.present? ? 422 : 404
        message = "There is no draft content item to discard"

        raise CommandError.new(code: code, message: message)
      end

      def delete_draft_from_database
        document.draft.destroy
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

      def delete_supporting_objects(content_item)
        Location.find_by(edition: content_item).try(:destroy)
        State.find_by(edition: content_item).try(:destroy)
        Translation.find_by(content_item: content_item).try(:destroy)
        UserFacingVersion.find_by(edition: content_item).try(:destroy)
        LockVersion.find_by(target: content_item).try(:destroy)
        AccessLimit.find_by(edition: content_item).try(:destroy)
        ChangeNote.where(edition: content_item).destroy_all
      end

      def increment_lock_version
        document.increment! :stale_lock_version
      end

      def document
        @document ||= Document.find_or_create_locked(
          content_id: payload[:content_id],
          locale: payload.fetch(:locale, Edition::DEFAULT_LOCALE),
        )
      end
    end
  end
end
