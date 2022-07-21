module Commands
  module V2
    class DiscardDraft < BaseCommand
      def call
        raise_error_if_missing_draft!

        check_version_and_raise_if_conflicting(document, payload[:previous_version])

        save_document_type
        delete_supporting_objects
        delete_draft_from_database
        increment_lock_version

        after_transaction_commit { downstream_discard_draft }

        Action.create_discard_draft_action(draft, locale, event)
        Success.new({ content_id: })
      end

    private

      delegate :draft, :content_id, :locale, to: :document

      def raise_error_if_missing_draft!
        return if draft.present?

        code = document.published_or_unpublished.present? ? 422 : 404
        message = "There is not a draft edition of this document to discard"

        raise CommandError.new(code:, message:)
      end

      def delete_draft_from_database
        draft.destroy
      end

      def downstream_discard_draft
        return unless downstream

        DownstreamDiscardDraftWorker.perform_async_in_queue(
          DownstreamDiscardDraftWorker::HIGH_QUEUE,
          base_path: draft.base_path,
          content_id:,
          locale:,
          update_dependencies: true,
          source_command: "discard_draft",
          source_document_type: @document_type,
        )
      end

      def delete_supporting_objects
        AccessLimit.where(edition: draft).delete_all
        ChangeNote.where(edition: draft).delete_all
        delete_path_reservation
      end

      def delete_path_reservation
        return unless draft.base_path
        return if Edition.exists?(base_path: draft.base_path,
                                  content_store: :live,
                                  publishing_app: draft.publishing_app)

        PathReservation
          .where(base_path: draft.base_path, publishing_app: draft.publishing_app)
          .delete_all
      end

      def increment_lock_version
        document.increment!(:stale_lock_version)
      end

      def document
        @document ||= Document.find_or_create_locked(
          content_id: payload[:content_id],
          locale: payload.fetch(:locale, Edition::DEFAULT_LOCALE),
        )
      end

      # We pass the document type into the `DownstreamDiscardDraftWorker` which
      # passes it down to the `DependencyResolutionWorker`. The reason we do
      # this here and not in the discard draft worker is because the edition
      # may have already been destroyed by the time the worker runs, and it
      # wouldn't be able to access the destroyed edition's document type.
      def save_document_type
        @document_type = draft.document_type
      end
    end
  end
end
