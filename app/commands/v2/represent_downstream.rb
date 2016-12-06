module Commands
  module V2
    class RepresentDownstream
      def self.name
        self.to_s
      end

      def call(scope, draft = false)
        filter = ContentItemFilter.new(scope: scope)

        if draft
          content_ids = content_ids_for_draft_store(filter)
          with_locales = Queries::LocalesForContentItems.call(content_ids, draft_states)
          with_locales.each { |(content_id, locale)| downstream_draft(content_id, locale) }
        end

        content_ids = content_ids_for_live_store(filter)
        with_locales = Queries::LocalesForContentItems.call(content_ids, live_states)
        with_locales.each_with_index do |(content_id, locale), index|
          sleep 60 if (index + 1) % 10_000 == 0
          downstream_live(content_id, locale)
        end
      end

    private

      def content_ids_for_draft_store(filter)
        Queries::GetLatest.call(filter.filter(state: draft_states)).distinct.pluck(:content_id)
      end

      def content_ids_for_live_store(filter)
        filter.filter(state: live_states).distinct.pluck(:content_id)
      end

      def draft_states
        %w{draft published unpublished}
      end

      def live_states
        %w{published unpublished}
      end

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
