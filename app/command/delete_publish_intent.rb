class Command::DeletePublishIntent
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

  def call
    live_content_store.delete_publish_intent(base_path)
  end

private

  def live_content_store
    PublishingAPI.services(:live_content_store)
  end
end
