module Commands
  module V2
    class Publish < BaseCommand
      def call
        validate!

        live_content_item = LiveContentItem.create_or_replace(draft_item.attributes.except("access_limited")) do |live_item|
          raise CommandError.new(code: 400, message: "This item is already published") if live_item.version == draft_item.version
        end

        link_set = LinkSet.find_by(content_id: content_id)

        item_for_content_store = live_payload(live_content_item, link_set)
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

      def draft_item
        if (draft_content_item = DraftContentItem.find_by(content_id: content_id))
          draft_content_item
        else
          message = "Item with content_id #{content_id} does not exist"
          raise CommandError.new(code: 404, message: message)
        end
      end

      def link_set_hash(link_set)
        if link_set.present?
          {links: link_set.links}
        else
          {}
        end
      end

      def live_payload(live_item, link_set)
        Presenters::ContentItemPresenter.new(live_item).present.merge(link_set_hash(link_set))
      end

      def send_to_message_queue!(item_for_content_store)
        message_payload = item_for_content_store.merge(update_type: update_type)
        PublishingAPI.service(:queue_publisher).send_message(message_payload)
      end
    end
  end
end
