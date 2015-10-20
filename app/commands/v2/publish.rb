module Commands
  module V2
    class Publish < BaseCommand
      def call
        validate!

        live_content_item = LiveContentItem.create_or_replace(live_item_attributes) do |live_item|
          if live_item.version == draft_item.version
            raise CommandError.new(code: 400, message: "This item is already published")
          end
        end

        item_for_content_store = live_payload(live_content_item)
        Adapters::ContentStore.call(live_content_item.base_path, item_for_content_store)

        send_to_message_queue!(item_for_content_store)

        Success.new(content_id: content_id)
      end

    private
      def validate!
        raise CommandError.new(
          code: 422,
          message: "update_type is required",
          error_details: {
            error: {
              code: 422,
              message: "update_type is required",
              fields: {
                update_type: ["is required"],
              }
            }
          }
        ) unless update_type.present?
      end

      def content_id
        payload[:content_id]
      end

      def update_type
        payload[:update_type]
      end

      def live_item_attributes
        attributes = draft_item
          .attributes
          .except("access_limited", "version")
          .merge(draft_content_item: draft_item)
      end

      def draft_item
        if (draft_content_item = DraftContentItem.find_by(content_id: content_id))
          draft_content_item
        else
          message = "Item with content_id #{content_id} does not exist"
          raise CommandError.new(code: 404, message: message)
        end
      end

      def live_payload(live_item)
        live_item_hash = LinkSetMerger.merge_links_into(live_item)
        Presenters::ContentItemPresenter.present(live_item_hash)
      end

      def send_to_message_queue!(item_for_content_store)
        message_payload = item_for_content_store.merge(update_type: update_type)
        PublishingAPI.service(:queue_publisher).send_message(message_payload)
      end
    end
  end
end
