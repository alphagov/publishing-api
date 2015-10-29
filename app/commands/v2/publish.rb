module Commands
  module V2
    class Publish < BaseCommand
      def call
        validate!

        draft = lookup_content_item
        publish_content_item(draft)

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

      def locale
        payload[:locale] || DraftContentItem::DEFAULT_LOCALE
      end

      def update_type
        payload[:update_type]
      end

      def lookup_content_item
        draft = DraftContentItem.find_by(content_id: content_id, locale: locale)

        unless draft
          message = "Item with content_id #{content_id} and locale #{locale} does not exist"
          raise CommandError.new(code: 404, message: message)
        end

        draft
      end

      def publish_content_item(draft_content_item)
        attributes = build_live_attributes(draft_content_item)

        live_content_item = LiveContentItem.create_or_replace(attributes) do |live_item|
          live_version = Version.find_or_initialize_by(target: live_item)
          draft_version = Version.find_or_initialize_by(target: draft_content_item)

          if live_version.number == draft_version.number
            raise CommandError.new(code: 400, message: "This item is already published")
          else
            version = Version.find_or_initialize_by(target: live_item)
            version.copy_version_from(draft_content_item)
            version.save!
          end
        end

        item_for_content_store = content_store_payload(live_content_item)
        Adapters::ContentStore.call(live_content_item.base_path, item_for_content_store)

        send_to_message_queue!(item_for_content_store)
      end

      def build_live_attributes(draft_content_item)
        attributes = draft_content_item
          .attributes
          .except("access_limited", "version")
          .merge(draft_content_item: draft_content_item)
      end

      def content_store_payload(live_item)
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
