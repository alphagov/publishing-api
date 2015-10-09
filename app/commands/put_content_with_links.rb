module Commands
  class PutContentWithLinks < BaseCommand
    def call
      if content_item[:content_id]
        create_or_update_live_content_item!
        create_or_update_draft_content_item!
        create_or_update_links!
      end

      Adapters::UrlArbiter.call(base_path, content_item[:publishing_app])
      Adapters::DraftContentStore.call(base_path, content_item_without_access_limiting)
      Adapters::ContentStore.call(base_path, content_item_without_access_limiting)

      PublishingAPI.service(:queue_publisher).send_message(content_item_with_base_path)

      Success.new(content_item_without_access_limiting)
    end

  private
    def content_item
      payload.except(:base_path)
    end

    def content_id
      content_item[:content_id]
    end

    def content_item_without_access_limiting
      content_item.except(:access_limited)
    end

    def content_item_with_base_path
      content_item_without_access_limiting.merge(base_path: base_path)
    end

    def content_item_top_level_fields
      LiveContentItem::TOP_LEVEL_FIELDS
    end

    def metadata
      content_item_without_access_limiting.except(*content_item_top_level_fields)
    end

    def create_or_update_live_content_item!
      LiveContentItem.create_or_replace(content_item_attributes)
    end

    def create_or_update_draft_content_item!
      DraftContentItem.create_or_replace(content_item_attributes)
    end

    def content_item_attributes
      content_item_with_base_path.slice(*content_item_top_level_fields).merge(metadata: metadata)
    end

    def create_or_update_links!
      LinkSet.create_or_replace(content_id: content_id, links: content_item[:links])
    end
  end
end
