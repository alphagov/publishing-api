class Command::PutContentWithLinks < Command::BaseCommand
  def call
    Adapters::UrlArbiter.new(services: services).call(base_path, content_item[:publishing_app])
    Adapters::DraftContentStore.new(services: services).call(base_path, content_item_without_access_limiting)
    Adapters::ContentStore.new(services: services).call(base_path, content_item_without_access_limiting)

    queue_publisher.send_message(content_item_with_base_path)

    Command::Success.new(content_item_without_access_limiting)
  end

private
  def content_item
    payload.deep_symbolize_keys.except(:base_path)
  end

  def content_item_without_access_limiting
    @content_item_without_access_limiting ||= content_item.except(:access_limited)
  end

  def content_item_with_base_path
    content_item_without_access_limiting.merge(base_path: base_path)
  end
end
