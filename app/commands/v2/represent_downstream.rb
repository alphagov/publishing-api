module Commands
  module V2
    class RepresentDownstream
      def self.name
        "Commands::V2::RepresentDownstream"
      end

      def call(scope)
        filter = ContentItemFilter.new(scope: scope)

        draft_content_items = Queries::GetLatest.call(
          filter.filter(state: %w{draft published}))
        live_content_items = filter.filter(state: "published")

        draft_content_items.each do |draft_content_item|
          send_to_content_store(draft_content_item, Adapters::DraftContentStore)
        end

        live_content_items.each do |live_content_item|
          send_to_content_store(live_content_item, Adapters::ContentStore)
        end
      end

      def send_to_content_store(content_item, content_store)
        payload = { content_id: content_item.content_id, message: "Representing to #{content_store}" }
        EventLogger.log_command(self.class, payload) do |event|
          PresentedContentStoreWorker.perform_async_in_queue(
            PresentedContentStoreWorker::LOW_QUEUE,
            content_store: content_store,
            payload: { content_item_id: content_item.id, payload_version: event.id },
            request_uuid: nil
          )
        end
      end
    end
  end
end
