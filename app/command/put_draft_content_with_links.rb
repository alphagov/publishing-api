class Command::PutDraftContentWithLinks < Command::BaseCommand
  def call
    Adapters::UrlArbiter.new(services: services).call(base_path, content_item[:publishing_app])
    Adapters::DraftContentStore.new(services: services).call(base_path, content_item)

    Command::Success.new(content_item)
  end

private
  def content_item
    payload.deep_symbolize_keys.except(:base_path)
  end

  def should_suppress?(error)
    PublishingAPI.swallow_draft_connection_errors && error.code == 502
  end
end
