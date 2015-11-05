module Commands
  class PutContentWithLinks < BaseCommand
    def call(downstream: true)
      if content_item[:content_id]
        draft_content_item = create_or_update_draft_content_item!
        create_or_update_live_content_item!(draft_content_item)
        create_or_update_links!
        create_or_update_content_item_links!
      end

      PathReservation.reserve_base_path!(base_path, content_item[:publishing_app])

      if downstream
        Adapters::DraftContentStore.call(base_path, content_item_for_content_store)
        Adapters::ContentStore.call(base_path, content_item_for_content_store)

        PublishingAPI.service(:queue_publisher).send_message(content_item_for_message_bus)
      end

      Success.new(content_item)
    end

  private
    def content_item
      payload.except(:base_path)
    end

    def content_id
      content_item[:content_id]
    end

    def content_item_for_content_store
      content_item.except(:access_limited, :update_type)
    end

    def content_item_for_message_bus
      content_item.except(:access_limited).merge(base_path: base_path)
    end

    def content_item_top_level_fields
      LiveContentItem::TOP_LEVEL_FIELDS
    end

    def create_or_update_live_content_item!(draft_content_item)
      attributes = content_item_attributes.merge(
        draft_content_item: draft_content_item
      )

      LiveContentItem.create_or_replace(attributes) do |item|
        version = Version.find_or_initialize_by(target: item)
        version.copy_version_from(draft_content_item)
        version.save! if item.valid?

        item.assign_attributes_with_defaults(attributes)
      end
    end

    def create_or_update_draft_content_item!
      DraftContentItem.create_or_replace(content_item_attributes) do |item|
        version = Version.find_or_initialize_by(target: item)
        version.increment
        version.save! if item.valid?

        item.assign_attributes_with_defaults(content_item_attributes)
      end
    end

    def content_item_attributes
      payload
        .slice(*content_item_top_level_fields)
        .merge(mutable_base_path: true)
    end

    def create_or_update_links!
      LinkSet.create_or_replace(content_id: content_id, links: content_item[:links]) do |link_set|
        version = Version.find_or_initialize_by(target: link_set)
        version.increment
        version.save! if link_set.valid?
      end
    end

    def create_or_update_content_item_links!
      ContentItemLinkPopulator.create_or_replace(content_id, content_item[:links] || {})
    end
  end
end
