class Command::PutContentWithLinks < Command::BaseCommand
  def call
    if content_item[:content_id]
      create_or_update_live_content_item!
      create_or_update_draft_content_item!
      create_or_update_links!
    end

    Adapters::UrlArbiter.new(services: services).call(base_path, content_item[:publishing_app])
    Adapters::DraftContentStore.new(services: services).call(base_path, content_item_without_access_limiting)
    Adapters::ContentStore.new(services: services).call(base_path, content_item_without_access_limiting)

    queue_publisher.send_message(content_item_with_base_path)

    Command::Success.new(content_item_without_access_limiting)
  end

private
  def content_item
    @content_item ||= payload.deep_symbolize_keys.except(:base_path)
  end

  def content_id
    content_item[:content_id]
  end

  def content_item_without_access_limiting
    @content_item_without_access_limiting ||= content_item.except(:access_limited)
  end

  def content_item_with_base_path
    content_item_without_access_limiting.merge(base_path: base_path)
  end

  def metadata
    content_item_without_access_limiting.except(*content_item_top_level_fields)
  end

  def create_or_update_live_content_item!
    existing = LiveContentItem.find_by(content_id: content_id, locale: content_item[:locale])
    if existing
      if existing.base_path != base_path
        raise Command::Error.new(
          code: 400,
          message: "Cannot change base path",
          error_details: { errors: { base_path: "cannot change once item is live" } }
        )
      end
      existing.update_attributes(content_item_attributes)
      existing.version += 1
      existing.save!
    else
      LiveContentItem.create!(content_item_attributes.merge(version: 1))
    end
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
      base_path
      content_id
      details
      format
      locale
      publishing_app
      rendering_app
      public_updated_at
      description
      title
      routes
    )
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
