class Command::PutPublishIntent < Command::BaseCommand
  attr_reader :event

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
end
