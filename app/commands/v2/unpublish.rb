module Commands
  module V2
    class Unpublish < BaseCommand
      def call
        content_id = payload.fetch(:content_id)
        content_item = find_live_content_item(content_id)

        case payload.fetch(:type)
        when "withdrawal"
          withdraw(content_item)
        when "redirect"
          redirect(content_item)
        when "gone"
          gone(content_item)
        end

        Success.new(content_id: content_id)
      end

    private

      def withdraw(content_item)
        unpublishing = State.unpublish(content_item,
          type: "withdrawal",
          explanation: payload.fetch(:explanation),
        )

        send_content_item_downstream(content_item, unpublishing) if downstream
      end

      def redirect(content_item)
        unpublishing = State.unpublish(content_item,
          type: "redirect",
          alternative_path: payload.fetch(:alternative_path),
        )

        send_arbitrary_downstream(RedirectPresenter.present(
          base_path: Location.find_by(content_item: content_item).base_path,
          publishing_app: content_item.publishing_app,
          destination: unpublishing.alternative_path,
          public_updated_at: Time.zone.now,
        )) if downstream
      end

      def gone(content_item)
        unpublishing = State.unpublish(content_item,
          type: "gone",
          alternative_path: payload[:alternative_path],
          explanation: payload[:explanation],
        )

        send_arbitrary_downstream(GonePresenter.present(
          base_path: Location.find_by(content_item: content_item).base_path,
          publishing_app: content_item.publishing_app,
          alternative_path: payload[:alternative_path],
          explanation: payload[:explanation],
        )) if downstream
      end

      def send_arbitrary_downstream(downstream_payload)
        PresentedContentStoreWorker.perform_async(
          content_store: Adapters::ContentStore,
          payload: downstream_payload,
          request_uuid: GdsApi::GovukHeaders.headers[:govuk_request_id]
        )
      end

      def locale
        payload.fetch(:locale, ContentItem::DEFAULT_LOCALE)
      end

      def find_live_content_item(content_id)
        filter = ContentItemFilter.new(scope: ContentItem.where(content_id: content_id))
        filter.filter(locale: locale, state: "published").first
      end

      def send_content_item_downstream(content_item, unpublishing)
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
