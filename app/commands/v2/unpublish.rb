module Commands
  module V2
    class Unpublish < BaseCommand
      def call
        validate
        State.supersede(previous_item) if previous_item
        transision_state
        delete_linkable

        after_transaction_commit do
          send_downstream
        end

        Success.new(content_id: content_id)
      end

    private

      def transision_state
        raise_invalid_type unless valid_type?
        method = {
          "withdrawal" => method(:withdraw),
          "redirect" => method(:redirect),
          "vanish" => method(:vanish),
          "gone" => method(:gone),
        }[type].call
      end

      def valid_type?
        %w(withdrawal redirect gone vanish).include?(type)
      end

      def type
        payload.fetch(:type)
      end

      def raise_invalid_type
        message = "#{type} is not a valid unpublishing type"
        raise_command_error(422, message, fields: {})
      end

      def content_item
        @content_item ||= find_unpublishable_content_item
      end

      def content_id
        @content_id ||= payload.fetch(:content_id)
      end

      def validate_allow_discard_draft!
        if payload[:allow_draft] && payload[:discard_drafts]
          message = "allow_draft and discard_drafts cannot be used together"
          raise_command_error(422, message, fields: {})
        end
      end

      def validate_content_item_presence!
        unless content_item.present?
          message = "Could not find a content item to unpublish"
          raise_command_error(404, message, fields: {})
        end
      end

      def validate_draft_presence!
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
        validate_allow_discard_draft!
        validate_content_item_presence!
        check_version_and_raise_if_conflicting(content_item, previous_version_number)
        validate_draft_presence!
      end

      def withdraw
        State.unpublish(content_item,
          type: "withdrawal",
          explanation: payload.fetch(:explanation),
        )
      end

      def redirect
        State.unpublish(content_item,
          type: "redirect",
          alternative_path: payload.fetch(:alternative_path),
        )
      end

      def gone
        State.unpublish(content_item,
          type: "gone",
          alternative_path: payload[:alternative_path],
          explanation: payload[:explanation],
        )
      end

      def vanish
        State.unpublish(content_item, type: "vanish")
      end

      def delete_linkable
        Linkable.find_by(content_item: content_item).try(:destroy)
      end

      def send_downstream
        return unless downstream

        DownstreamDraftWorker.perform_async_in_queue(
          DownstreamDraftWorker::HIGH_QUEUE,
          content_item_id: content_item.id,
          payload_version: event.id,
          update_dependencies: true,
        )

        DownstreamLiveWorker.perform_async_in_queue(
          DownstreamLiveWorker::HIGH_QUEUE,
          content_item_id: content_item.id,
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

        filter = ContentItemFilter.new(scope: ContentItem.where(content_id: content_id))
        content_item = filter.filter(locale: locale, state: allowed_states).last
        content_item if content_item && (payload[:allow_draft] || !Unpublishing.is_substitute?(content_item))
      end

      def previous_item
        raise "There should only be one previous published or unpublished item" if previous_items.size > 1
        previous_items.first
      end

      def previous_items
        @previous_items ||= ContentItemFilter.similar_to(
          content_item,
          state: %w(published unpublished),
          base_path: nil,
          user_version: nil,
        ).to_a
      end

      def draft_exists?
        filter = ContentItemFilter.new(scope: ContentItem.where(content_id: content_id))
        filter.filter(locale: locale, state: "draft").exists?
      end
    end
  end
end
