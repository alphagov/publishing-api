module Commands
  module V2
    class ChangeOwnership < BaseCommand
      def call
        if publishing_app.blank?
          raise_command_error(422, "publishing_app is required", fields: {
            publishing_app: ["is required"]
          })
        end

        content_item = find_content_item

        raise_command_error(
          404,
          "Item with content_id #{content_id} does not exist",
          fields: {}
        ) if content_item.nil?

        update_publishing_app(content_item)

        after_transaction_commit do
          send_downstream(content_item)
        end

        response_hash = Presenters::Queries::ContentItemPresenter.present(content_item)
        Success.new(response_hash)
      end

    private

      def content_id
        payload[:content_id]
      end

      def send_downstream(content_item)
        return unless downstream

        message = "Enqueuing PresentedContentStoreWorker job with "
        message += "{ content_store: Adapters::DraftContentStore, content_item_id: #{content_item.id} }"
        logger.info message

        PresentedContentStoreWorker.perform_async_in_queue(
          content_store_queue,
          content_store: Adapters::DraftContentStore,
          payload: { content_item_id: content_item.id, payload_version: event.id },
        )
      end

      def update_publishing_app(content_item)
        content_item.publishing_app = payload[:publishing_app]
        content_item.save!
      end

      def find_content_item
        ContentItem.where(content_id: content_id).lock.first
      end

      def publishing_app
        payload[:publishing_app]
      end

      def content_store_queue
        PresentedContentStoreWorker::LOW_QUEUE
      end
    end
  end
end
