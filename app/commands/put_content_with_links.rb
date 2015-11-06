module Commands
  class PutContentWithLinks < BaseCommand
    def call(downstream: true)
      if content_item[:content_id]
        draft_content_item = create_or_update_draft_content_item!
        create_or_update_live_content_item!(draft_content_item)
        create_or_update_links!
      end

      PathReservation.reserve_base_path!(base_path, content_item[:publishing_app])

      if downstream
        content_store_payload = Presenters::ContentStorePresenter::V1.present(
          content_item,
          access_limited: false,
          update_type: false
        )

        Adapters::DraftContentStore.call(base_path, content_store_payload)
        Adapters::ContentStore.call(base_path, content_store_payload)

        message_bus_payload = Presenters::ContentStorePresenter::V1.present(
          payload,
          access_limited: false,
        )
        PublishingAPI.service(:queue_publisher).send_message(message_bus_payload)
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
  end
end
