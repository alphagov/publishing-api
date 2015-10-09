module Commands
  class PutDraftContentWithLinks < PutContentWithLinks
    def call
      if content_item[:content_id]
        create_or_update_draft_content_item!
        create_or_update_links!
      end

      Adapters::UrlArbiter.new.call(base_path, content_item[:publishing_app])
      Adapters::DraftContentStore.new.call(base_path, content_item)

      Success.new(content_item)
    end

  private
    def content_item_with_base_path
      content_item.merge(base_path: base_path)
    end

    def content_item_top_level_fields
      super << :access_limited
    end
  end
end
