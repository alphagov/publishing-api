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
        end

        Success.new(content_id: content_id)
      end

    private

      def withdraw(content_item)
        unpublishing = Unpublishing.create!(
          type: "withdrawal",
          explanation: payload.fetch(:explanation),
          content_item: content_item,
        )

        send_content_item_downstream(content_item, unpublishing) if downstream
      end

      def redirect(content_item)
        unpublishing = Unpublishing.create!(
          type: "redirect",
          alternative_path: payload.fetch(:alternative_path),
          content_item: content_item,
        )

        send_redirect_downstream(
          base_path: Location.find_by(content_item: content_item).base_path,
          publishing_app: content_item.publishing_app,
          destination: unpublishing.alternative_path
        ) if downstream
      end

      def send_redirect_downstream(base_path:, publishing_app:, destination:)
        downstream_payload = {
          format: "redirect",
          base_path: base_path,
          publishing_app: publishing_app,
          public_updated_at: Time.zone.now.iso8601,
          redirects: [
            {
              path: base_path,
              type: "exact",
              destination: destination,
            }
          ],
        }

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
