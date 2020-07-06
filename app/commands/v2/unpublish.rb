module Commands
  module V2
    class Unpublish < BaseCommand
      def call
        validate

        previous.supersede if previous_edition_should_be_superseded?
        transition_state
        reset_draft_access

        after_transaction_commit do
          send_downstream
        end

        Action.create_unpublish_action(
          edition,
          unpublishing_type,
          document.locale,
          event,
        )

        Success.new(content_id: document.content_id)
      end

    private

      def transition_state
        raise_invalid_unpublishing_type unless valid_unpublishing_type?
        unpublish
      end

      def reset_draft_access
        edition.update!(auth_bypass_ids: []) if edition.auth_bypass_ids.any?
        AccessLimit.where(edition: edition).delete_all
      end

      def valid_unpublishing_type?
        %w[withdrawal redirect gone vanish].include?(unpublishing_type)
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
        if edition.blank?
          message = "Could not find an edition to unpublish"
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
        if edition.draft?
          Edition::Timestamps.live_transition(edition, edition.update_type, previous)
        end

        edition.unpublish(
          payload
            .slice(:type, :explanation, :alternative_path, :unpublished_at)
            .merge(redirects: redirects),
        )
      rescue ActiveRecord::RecordInvalid => e
        raise_command_error(422, e.message, fields: {})
      end

      def redirects
        if unpublishing_type == "redirect" && payload[:alternative_path]
          [{
            path: edition.base_path,
            type: :exact,
            destination: payload[:alternative_path],
          }]
        else
          payload[:redirects]
        end
      end

      def send_downstream
        return unless downstream

        DownstreamDraftWorker.perform_async_in_queue(
          DownstreamDraftWorker::HIGH_QUEUE,
          content_id: document.content_id,
          locale: document.locale,
          update_dependencies: true,
          source_command: "unpublish",
        )

        DownstreamLiveWorker.perform_async_in_queue(
          DownstreamLiveWorker::HIGH_QUEUE,
          content_id: document.content_id,
          locale: document.locale,
          update_dependencies: true,
          orphaned_content_ids: orphaned_content_ids,
          message_queue_event_type: "unpublish",
          source_command: "unpublish",
        )
      end

      def previous_version_number
        payload[:previous_version].to_i if payload[:previous_version]
      end

      def orphaned_content_ids
        return [] if !payload[:allow_draft] || !previous

        previous_links = previous.links.map(&:target_content_id)
        current_links = find_unpublishable_edition.links.map(&:target_content_id)
        previous_links - current_links
      end

      def find_unpublishable_edition
        if payload[:allow_draft]
          document.draft
        elsif previous && !Unpublishing.is_substitute?(previous)
          previous
        end
      end

      def previous
        document.published_or_unpublished
      end

      def previous_edition_should_be_superseded?
        previous && (find_unpublishable_edition != previous)
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
