module Commands
  module V2
    class Unpublish < BaseCommand
      def call
        validate
        document.live.supersede if live_edition_should_be_superseded?
        transition_state
        AccessLimit.find_by(content_item: content_item).try(:destroy)

        after_transaction_commit do
          send_downstream
        end

        Action.create_unpublish_action(content_item, unpublishing_type, locale, event)

        Success.new(content_id: content_id)
      end

    private

      def transition_state
        raise_invalid_unpublishing_type unless valid_unpublishing_type?
        unpublish
      end

      def valid_unpublishing_type?
        %w(withdrawal redirect gone vanish).include?(unpublishing_type)
      end

      def unpublishing_type
        payload.fetch(:type)
      end

      def raise_invalid_unpublishing_type
        message = "#{unpublishing_type} is not a valid unpublishing type"
        raise_command_error(422, message, fields: {})
      end

      def content_item
        @content_item ||= find_unpublishable_content_item
      end

      def content_id
        @content_id ||= payload.fetch(:content_id)
      end

      def validate_allow_discard_draft
        if payload[:allow_draft] && payload[:discard_drafts]
          message = "allow_draft and discard_drafts cannot be used together"
          raise_command_error(422, message, fields: {})
        end
      end

      def validate_content_item_presence
        unless content_item.present?
          message = "Could not find a content item to unpublish"
          raise_command_error(404, message, fields: {})
        end
      end

      def validate_draft_presence
        if draft_exists? && !payload[:allow_draft]
          if payload[:discard_drafts] == true
            DiscardDraft.call(
              {
                content_id: content_id,
                locale: locale,
              },
              downstream: downstream,
              callbacks: callbacks,
              nested: true,
            )
          else
            message = "Cannot unpublish with a draft present"
            raise_command_error(422, message, fields: {})
          end
        end
      end

      def validate
        validate_allow_discard_draft
        validate_content_item_presence
        check_version_and_raise_if_conflicting(content_item, previous_version_number)
        validate_draft_presence
      end

      def unpublish
        content_item.unpublish(payload.slice(:type, :explanation, :alternative_path, :unpublished_at))
      rescue ActiveRecord::RecordInvalid => e
        raise_command_error(422, e.message, fields: {})
      end

      def send_downstream
        return unless downstream

        DownstreamDraftWorker.perform_async_in_queue(
          DownstreamDraftWorker::HIGH_QUEUE,
          content_id: content_item.content_id,
          locale: locale,
          payload_version: event.id,
          update_dependencies: true,
        )

        DownstreamLiveWorker.perform_async_in_queue(
          DownstreamLiveWorker::HIGH_QUEUE,
          content_id: content_item.content_id,
          locale: locale,
          payload_version: event.id,
          update_dependencies: true,
        )
      end

      def locale
        payload.fetch(:locale, ContentItem::DEFAULT_LOCALE)
      end

      def previous_version_number
        payload[:previous_version].to_i if payload[:previous_version]
      end

      def find_unpublishable_content_item
        allowed_states = %w(published unpublished)

        if payload[:allow_draft]
          allowed_states = %w(draft)
        end

        content_item = document.content_items.where(state: allowed_states)
          .order(nil).lock.first

        content_item if content_item && (payload[:allow_draft] || !Unpublishing.is_substitute?(content_item))
      end

      def live_edition_should_be_superseded?
        document.live && find_unpublishable_content_item != document.live
      end

      def previous_item
        document.previous_item
      end

      def document
        @document ||= Document.find_or_create_locked(
          content_id: content_id,
          locale: locale,
        )
      end

      def draft_exists?
        document.content_items.where(state: "draft").exists?
      end
    end
  end
end
