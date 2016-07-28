module Commands
  module V2
    class RepresentDownstream
      def self.name
        self.to_s
      end

      def call(scope, draft = false)
        filter = ContentItemFilter.new(scope: scope)

        if draft
          items_for_draft_store(filter).pluck(:id, :content_id).each do |(content_item_id, content_id)|
            send_to_content_store(content_item_id, content_id, Adapters::DraftContentStore)
          end
        end

        items_for_live_store(filter).pluck(:id, :content_id).each_with_index do |(content_item_id, content_id), index|
          sleep 60 if (index + 1) % 10_000 == 0
          downstream_publish(content_item_id, content_id)
        end
      end

    private

      def items_for_draft_store(filter)
        Queries::GetLatest.call(
          filter.filter(state: %w{draft published})
        )
      end

      def items_for_live_store(filter)
        filter.filter(state: "published")
      end

      def send_to_content_store(content_item_id, content_id, content_store)
        payload = {
          content_id: content_id,
          message: "Representing to #{content_store}"
        }

        EventLogger.log_command(self.class, payload) do |event|
          PresentedContentStoreWorker.perform_async_in_queue(
            PresentedContentStoreWorker::LOW_QUEUE,
            content_store: content_store,
            payload: { content_item_id: content_item_id, payload_version: event.id },
            enqueue_dependency_check: false,
          )
        end
      end

      def downstream_publish(content_item_id, content_id)
        event_payload = {
          content_id: content_id,
          message: "Representing downstream publish",
        }

        EventLogger.log_command(self.class, event_payload) do |event|
          DownstreamPublishWorker.perform_async_in_queue(
            DownstreamPublishWorker::LOW_QUEUE,
            content_item_id: content_item_id,
            payload_version: event.id,
            message_queue_update_type: "links",
            send_to_content_store: true,
            update_dependencies: false,
          )
        end
      end
    end
  end
end
