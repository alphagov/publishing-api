module Commands
  class PutDraftContentWithLinks < BaseCommand
    def call
      add_links_if_not_provided

      if payload[:content_id]
        V2::PutContent.call(payload)
        V2::PutLinkSet.call(payload.slice(:content_id, :links))
      else
        PathReservation.reserve_base_path!(base_path, payload[:publishing_app])

        if downstream
          content_store_payload = Presenters::DownstreamPresenter::V1.present(payload, update_type: false)
          Adapters::DraftContentStore.put_content_item(base_path, content_store_payload)
        end
      end

      Success.new(payload)
    end

  private
    def base_path
      payload.fetch(:base_path)
    end

    def draft_content_item
      @draft_content_item ||= ContentItemFilter.new(scope: ContentItem.where(content_id: payload[:content_id]))
        .filter(
          locale: locale,
          state: "draft",
        ).first
    end

    def locale
      payload.fetch(:locale, ContentItem::DEFAULT_LOCALE)
    end

    def add_links_if_not_provided
      return if payload[:links].present?
      payload[:links] = {}
    end
  end
end
