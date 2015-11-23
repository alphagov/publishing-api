module Commands
  class PutDraftContentWithLinks < PutContentWithLinks
    def call(downstream: true)
      if content_item[:content_id]
        create_or_update_draft_content_item!
        create_or_update_links!
      end

      PathReservation.reserve_base_path!(base_path, content_item[:publishing_app])

      if downstream
        payload = Presenters::DownstreamPresenter::V1.present(
          content_item,
          update_type: false,
          access_limited: true,
        )
        Adapters::DraftContentStore.put_content_item(base_path, payload)
      end

      Success.new(content_item)
    end

  private
    def content_item_top_level_fields
      DraftContentItem::TOP_LEVEL_FIELDS
    end
  end
end
