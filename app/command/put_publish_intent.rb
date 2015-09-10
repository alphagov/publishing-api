class Command::PutPublishIntent
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
    url_arbiter.reserve_path(
      base_path,
      publishing_app: content_item[:publishing_app]
    )

    live_content_store.put_publish_intent(
      base_path: base_path,
      publish_intent: content_item
    )
  rescue GOVUK::Client::Errors::HTTPError => e
    raise UrlArbitrationError.new(e)
  end

private

  def live_content_store
    PublishingAPI.services(:live_content_store)
  end

  def url_arbiter
    PublishingAPI.services(:url_arbiter)
  end
end
