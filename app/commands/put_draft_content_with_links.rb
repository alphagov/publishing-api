module Commands
  class PutDraftContentWithLinks < BaseCommand
    def call
      if payload[:content_id]
        V2::PutContent.call(v2_put_content_payload, downstream: downstream, callbacks: callbacks, nested: true)
        V2::PatchLinkSet.call(v2_put_link_set_payload, downstream: downstream, callbacks: callbacks, nested: true)
      else
        PathReservation.reserve_base_path!(base_path, payload[:publishing_app])

        if downstream
          content_store_payload = Presenters::DownstreamPresenter::V1.present(
            payload,
            event,
            update_type: false
          )
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

    def v2_put_content_payload
      payload
        .except(:links)
    end

    def v2_put_link_set_payload
      payload
        .slice(:content_id, :links)
        .merge(links: payload[:links] || {})
    end
  end
end
