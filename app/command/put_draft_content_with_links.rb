class Command::PutDraftContentWithLinks < Command::BaseCommand
  def call
    if content_item[:content_id]
      create_or_update_draft_content_item!
      create_or_update_links!
    end

    Adapters::UrlArbiter.new(services: services).call(base_path, content_item[:publishing_app])
    Adapters::DraftContentStore.new(services: services).call(base_path, content_item)

    Command::Success.new(content_item)
  end

private
  def content_item
    payload.deep_symbolize_keys.except(:base_path)
  end

  def content_id
    content_item[:content_id]
  end

  def content_item_with_base_path
    content_item.merge(base_path: base_path)
  end

  def should_suppress?(error)
    PublishingAPI.swallow_draft_connection_errors && error.code == 502
  end

  def create_or_update_draft_content_item!
    existing = DraftContentItem.find_by(content_id: content_id, locale: content_item[:locale])
    if existing
      existing.update_attributes(content_item_attributes)
      existing.version += 1
      existing.save!
    else
      DraftContentItem.create!(content_item_attributes.merge(version: 1))
    end
  end

  def content_item_attributes
    content_item_with_base_path.slice(*content_item_top_level_fields).merge(metadata: metadata)
  end

  def content_item_top_level_fields
    %I(
      access_limited
      base_path
      content_id
      description
      details
      format
      locale
      public_updated_at
      publishing_app
      rendering_app
      routes
      title
    )
  end

  def metadata
    content_item.except(*content_item_top_level_fields)
  end

  def create_or_update_links!
    existing = LinkSet.find_by(content_id: content_id)
    if existing
      existing.update_attributes(links: content_item[:links])
      existing.version += 1
      existing.save!
    else
      LinkSet.create!(content_id: content_id, links: content_item[:links], version: 1)
    end
  end
end
