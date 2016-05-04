module Commands
  module V2
    class Unpublish < BaseCommand
      def call
        content_item = find_live_content_item

        unpublishing = Unpublishing.create!(
          type: "withdrawal",
          explanation: payload.fetch(:explanation),
          content_item: content_item,
        )

        send_downstream(content_item, unpublishing) if downstream

        Success.new(content_id: content_id)
      end

    private

      def content_id
        payload[:content_id]
      end

      def locale
        payload.fetch(:locale, ContentItem::DEFAULT_LOCALE)
      end

      def find_live_content_item
        filter = ContentItemFilter.new(scope: ContentItem.where(content_id: content_id))
        filter.filter(locale: locale, state: "published").first
      end

      def send_downstream(content_item, unpublishing)
        downstream_payload = Presenters::ContentStorePresenter.present(
          content_item,
          event,
          fallback_order: [:published]
        )

        downstream_payload.merge!(
          withdrawn_notice: {
            explanation: unpublishing.explanation,
            withdrawn_at: unpublishing.created_at.iso8601,
          }
        )

        PresentedContentStoreWorker.perform_async(
          content_store: Adapters::ContentStore,
          payload: downstream_payload,
          request_uuid: GdsApi::GovukHeaders.headers[:govuk_request_id]
        )
      end
    end
  end
end
