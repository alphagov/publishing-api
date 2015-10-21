module Commands
  class PutDraftContentWithLinks < PutContentWithLinks
    def call(downstream: true)
      if content_item[:content_id]
        create_or_update_draft_content_item!
        create_or_update_links!
      end

      if downstream
        Adapters::UrlArbiter.call(base_path, content_item[:publishing_app])
        Adapters::DraftContentStore.call(base_path, content_item_for_content_store)
      end

      Success.new(content_item)
    end

  private
    def content_item_for_content_store
      content_item.except(:update_type)
    end

    def content_item_top_level_fields
      DraftContentItem::TOP_LEVEL_FIELDS
    end
  end
end
