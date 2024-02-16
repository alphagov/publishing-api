module Commands
  module V2
    class RepresentDownstream
      def self.name
        to_s
      end

      def call(content_ids, with_drafts: true, queue: DownstreamQueue::LOW_QUEUE)
        if with_drafts
          with_locales = Queries::LocalesForEditions.call(content_ids, %w[draft live])
          with_locales.each { |(content_id, locale)| downstream_draft(content_id, locale, queue) }
        end

        with_locales = Queries::LocalesForEditions.call(content_ids, %w[live])
        with_locales.each { |(content_id, locale)| downstream_live(content_id, locale, queue) }
      end

    private

      def downstream_draft(content_id, locale, queue)
        event_payload = {
          content_id:,
          locale:,
          message: "Representing downstream draft",
        }

        EventLogger.log_command(self.class, event_payload) do |_event|
          DownstreamDraftWorker.new.perform(
            "content_id" => content_id,
            "locale" => locale,
            "update_dependencies" => false,
            "source_command" => "represent_downstream",
          )
        end
      end

      def downstream_live(content_id, locale, queue)
        event_payload = {
          content_id:,
          locale:,
          message: "Representing downstream live",
        }

        EventLogger.log_command(self.class, event_payload) do |_event|
          DownstreamLiveWorker.new.perform(
            "content_id" => content_id,
            "locale" => locale,
            "message_queue_event_type" => "links",
            "update_dependencies" => false,
            "source_command" => "represent_downstream",
          )
        end
      end
    end
  end
end
