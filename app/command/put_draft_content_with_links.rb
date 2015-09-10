class Command::PutDraftContentWithLinks
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

    draft_response = draft_content_store.put_content_item(
      base_path: base_path,
      content_item: content_item,
    )

    content_item
  rescue GdsApi::HTTPServerError => e
    raise e unless should_suppress?(e)
  rescue GOVUK::Client::Errors::HTTPError => e
    raise UrlArbitrationError.new(e)
  end

private
  def should_suppress?(error)
    ENV["SUPPRESS_DRAFT_STORE_502_ERROR"] && error.code == 502
  end

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
