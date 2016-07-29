module Commands
  module V2
    class Unpublish < BaseCommand
      def call
        if payload[:allow_draft] && payload[:discard_drafts]
          message = "allow_draft and discard_drafts cannot be used together"
          raise_command_error(422, message, fields: {})
        end

        content_id = payload.fetch(:content_id)
        content_item = find_unpublishable_content_item(content_id)

        unless content_item.present?
          message = "Could not find a content item to unpublish"
          raise_command_error(404, message, fields: {})
        end

        unless Location.where(content_item: content_item).exists?
          message = "Cannot unpublish content with no location"
          raise_command_error(422, message, fields: {})
        end

        check_version_and_raise_if_conflicting(content_item, previous_version_number)

        if draft_present?(content_id) && !payload[:allow_draft]
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

        previous_item = lookup_previous_item(content_item)
        State.supersede(previous_item) if previous_item

        case type = payload.fetch(:type)
        when "withdrawal"
          withdraw(content_item)
        when "redirect"
          redirect(content_item)
        when "gone"
          gone(content_item)
        when "vanish"
          vanish(content_item)
        else
          message = "#{type} is not a valid unpublishing type"
          raise_command_error(422, message, fields: {})
        end

        delete_linkable(content_item)

        after_transaction_commit do
          send_downstream_unpublish(content_item)
        end

        Success.new(content_id: content_id)
      end

    private

      def withdraw(content_item)
        State.unpublish(content_item,
          type: "withdrawal",
          explanation: payload.fetch(:explanation),
        )
      end

      def redirect(content_item)
        State.unpublish(content_item,
          type: "redirect",
          alternative_path: payload.fetch(:alternative_path),
        )
      end

      def gone(content_item)
        State.unpublish(content_item,
          type: "gone",
          alternative_path: payload[:alternative_path],
          explanation: payload[:explanation],
        )
      end

      def vanish(content_item)
        State.unpublish(content_item, type: "vanish")
      end

      def delete_linkable(content_item)
        Linkable.find_by(content_item: content_item).try(:destroy)
      end

      def send_downstream_unpublish(content_item)
        return unless downstream

        DownstreamUnpublishWorker.perform_async_in_queue(
          DownstreamUnpublishWorker::HIGH_QUEUE,
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

      def find_unpublishable_content_item(content_id)
        allowed_states = %w(published unpublished)

        if payload[:allow_draft]
          allowed_states = %w(draft)
        end

        filter = ContentItemFilter.new(scope: ContentItem.where(content_id: content_id))
        filter.filter(locale: locale, state: allowed_states).last
      end

      def lookup_previous_item(content_item)
        previous_items = ContentItemFilter.similar_to(
          content_item,
          state: %w(published unpublished),
          base_path: nil,
          user_version: nil,
        ).to_a

        if previous_items.size > 1
          raise "There should only be one previous published or unpublished item"
        end

        previous_items.first
      end

      def draft_present?(content_id)
        filter = ContentItemFilter.new(scope: ContentItem.where(content_id: content_id))
        filter.filter(locale: locale, state: "draft").exists?
      end

      def send_content_item_downstream(content_item)
        return unless downstream

        PresentedContentStoreWorker.perform_async(
          content_store: Adapters::ContentStore,
          payload: { content_item_id: content_item.id, payload_version: event.id },
        )
      end
    end
  end
end
