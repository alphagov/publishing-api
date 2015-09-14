class Command::BaseCommand
  attr_reader :event

  def initialize(event)
    @event = event
  end

  def base_path
    event.payload['base_path']
  end

  def content_item
    event.payload.deep_symbolize_keys.except(:base_path)
  end

private

  def draft_content_store
    PublishingAPI.services(:draft_content_store)
  end

  def live_content_store
    PublishingAPI.services(:live_content_store)
  end

  def queue_publisher
    PublishingAPI.services(:queue_publisher)
  end

  def url_arbiter
    PublishingAPI.services(:url_arbiter)
  end
end
