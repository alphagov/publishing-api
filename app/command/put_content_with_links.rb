class Command::PutContentWithLinks < Command::BaseCommand
  def call
    if content_item[:content_id]
      create_or_update_live_content_item!
      create_or_update_draft_content_item!
      create_or_update_links!
    end

    Adapters::UrlArbiter.new(services: PublishingAPI).call(base_path, content_item[:publishing_app])
    Adapters::DraftContentStore.new(services: PublishingAPI).call(base_path, content_item_without_access_limiting)
    Adapters::ContentStore.new(services: PublishingAPI).call(base_path, content_item_without_access_limiting)

    PublishingAPI.service(:queue_publisher).send_message(content_item_with_base_path)

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
    LiveContentItem.create_or_replace(content_item_attributes)
  end

  def create_or_update_draft_content_item!
    DraftContentItem.create_or_replace(content_item_attributes)
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
      redirects
      routes
    )
  end

  def create_or_update_links!
    LinkSet.create_or_replace(content_id: content_id, links: content_item[:links])
  end
end
