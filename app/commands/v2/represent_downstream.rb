module Commands
  module V2
    class RepresentDownstream
      def self.name
        self.to_s
      end

      def call(content_ids, draft = false)
        if draft
          with_locales = Queries::LocalesForEditions.call(content_ids, %w[draft live])
          with_locales.each { |(content_id, locale)| downstream_draft(content_id, locale) }
        end

        with_locales = Queries::LocalesForEditions.call(content_ids, %w[live])
        with_locales.each_with_index do |(content_id, locale), index|
          sleep 60 if (index + 1) % 10_000 == 0
          downstream_live(content_id, locale)
        end
      end

    private

      def downstream_draft(content_id, locale)
        event_payload = {
          content_id: content_id,
          locale: locale,
          message: "Representing downstream draft",
        }

        EventLogger.log_command(self.class, event_payload) do |event|
          DownstreamDraftWorker.perform_async_in_queue(
            DownstreamDraftWorker::LOW_QUEUE,
            content_id: content_id,
            locale: locale,
            payload_version: event.id,
            update_dependencies: false,
          )
        end
      end

      def downstream_live(content_id, locale)
        event_payload = {
          content_id: content_id,
          locale: locale,
          message: "Representing downstream live",
        }

        EventLogger.log_command(self.class, event_payload) do |event|
          DownstreamLiveWorker.perform_async_in_queue(
            DownstreamLiveWorker::LOW_QUEUE,
            content_id: content_id,
            locale: locale,
            payload_version: event.id,
            message_queue_update_type: "links",
            update_dependencies: false,
          )
        end
      end
    end
  end
end
