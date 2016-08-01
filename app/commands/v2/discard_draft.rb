module Commands
  module V2
    class DiscardDraft < BaseCommand
      def call
        raise_error_if_missing_draft!

        check_version_and_raise_if_conflicting(draft, payload[:previous_version])

        draft_path = Location.where(content_item: draft).pluck(:base_path).first

        delete_supporting_objects
        delete_draft_from_database
        increment_live_lock_version if live

        after_transaction_commit do
          downstream_discard_draft(draft_path, draft.content_id, live.try(:id))
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

      def downstream_discard_draft(path_used, content_id, live_content_item_id)
        return unless downstream

        DownstreamDiscardDraftWorker.perform_async_in_queue(
          DownstreamDiscardDraftWorker::HIGH_QUEUE,
          base_path: path_used,
          content_id: content_id,
          live_content_item_id: live_content_item_id,
          payload_version: event.id,
          update_dependencies: true,
        )
      end

      def send_live_to_draft_content_store(live)
        return unless downstream

        DownstreamDraftWorker.perform_async_in_queue(
          DownstreamDraftWorker::HIGH_QUEUE,
          content_item_id: live.id,
          payload_version: event.id,
          update_dependencies: true,
        )
      end

      def delete_supporting_objects
        State.find_by(content_item: draft).try(:destroy)
        Translation.find_by(content_item: draft).try(:destroy)
        Location.find_by(content_item: draft).try(:destroy)
        UserFacingVersion.find_by(content_item: draft).try(:destroy)
        LockVersion.find_by(target: draft).try(:destroy)
        AccessLimit.find_by(content_item: draft).try(:destroy)
        Linkable.find_by(content_item: draft).try(:destroy)
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
          state: %w(published unpublished),
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
