module Commands
  module V2
    class Unpublish < BaseCommand
      def call
        validate

        previous.supersede if previous_edition_should_be_superseded?
        transition_state
        AccessLimit.find_by(edition: edition).try(:destroy)

        after_transaction_commit do
          send_downstream
        end

        Action.create_unpublish_action(edition, unpublishing_type,
                                       document.locale, event)

        Success.new(content_id: document.content_id)
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

      def edition
        @edition ||= find_unpublishable_edition
      end

      def validate_allow_discard_draft
        if payload[:allow_draft] && payload[:discard_drafts]
          message = "allow_draft and discard_drafts cannot be used together"
          raise_command_error(422, message, fields: {})
        end
      end

      def validate_edition_presence
        unless edition.present?
          message = "Could not find a content item to unpublish"
          raise_command_error(404, message, fields: {})
        end
      end

      def validate_draft_presence
        if document.draft.present? && !payload[:allow_draft]
          if payload[:discard_drafts] == true
            DiscardDraft.call(
              {
                content_id: document.content_id,
                locale: document.locale,
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
        validate_edition_presence
        check_version_and_raise_if_conflicting(document, previous_version_number)
        validate_draft_presence
      end

      def unpublish
        edition.unpublish(payload.slice(:type, :explanation, :alternative_path, :unpublished_at))
      rescue ActiveRecord::RecordInvalid => e
        raise_command_error(422, e.message, fields: {})
      end

      def send_downstream
        return unless downstream

        DownstreamDraftWorker.perform_async_in_queue(
          DownstreamDraftWorker::HIGH_QUEUE,
          content_id: document.content_id,
          locale: document.locale,
          payload_version: event.id,
          update_dependencies: true,
        )

        DownstreamLiveWorker.perform_async_in_queue(
          DownstreamLiveWorker::HIGH_QUEUE,
          content_id: document.content_id,
          locale: document.locale,
          payload_version: event.id,
          update_dependencies: true,
        )
      end

      def previous_version_number
        payload[:previous_version].to_i if payload[:previous_version]
      end

      def find_unpublishable_edition
        if payload[:allow_draft]
          edition = document.draft
        else
          edition = previous
        end

        edition if edition && (payload[:allow_draft] || !Unpublishing.is_substitute?(edition))
      end

      def previous
        document.published_or_unpublished
      end

      def previous_edition_should_be_superseded?
        previous && find_unpublishable_edition != previous
      end

      def document
        @document ||= Document.find_or_create_locked(
          content_id: payload.fetch(:content_id),
          locale: payload.fetch(:locale, Edition::DEFAULT_LOCALE),
        )
      end
    end
  end
end
