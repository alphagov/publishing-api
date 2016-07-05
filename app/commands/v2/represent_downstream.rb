module Commands
  module V2
    class RepresentDownstream
      def self.name
        self.to_s
      end

      def call(scope)
        filter = ContentItemFilter.new(scope: scope)

        items_for_draft_store(filter).find_each do |draft_store_item|
          send_to_content_store(draft_store_item, Adapters::DraftContentStore)
        end

        items_for_live_store(filter).find_each do |live_store_item|
          send_to_content_store(live_store_item, Adapters::ContentStore)
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

      def send_to_content_store(content_item, content_store)
        payload = {
          content_id: content_item.content_id,
          message: "Representing to #{content_store}"
        }

        EventLogger.log_command(self.class, payload) do |event|
          PresentedContentStoreWorker.perform_async_in_queue(
            PresentedContentStoreWorker::LOW_QUEUE,
            content_store: content_store,
            payload: { content_item_id: content_item.id, payload_version: event.id },
          )
        end
      end
    end
  end
end
