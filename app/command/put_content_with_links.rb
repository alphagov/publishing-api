class Command::PutContentWithLinks < Command::BaseCommand
  def call
    url_arbiter.reserve_path(
      base_path,
      publishing_app: content_item[:publishing_app]
    )

    draft_content_store.put_content_item(
      base_path: base_path,
      content_item: content_item_without_access_limiting,
    )

    live_response = live_content_store.put_content_item(
      base_path: base_path,
      content_item: content_item_without_access_limiting,
    )

    queue_publisher.send_message(content_item_with_base_path)

    content_item_without_access_limiting
  rescue GdsApi::HTTPServerError => e
    raise e unless should_suppress?(e)
  rescue GOVUK::Client::Errors::HTTPError => e
    raise UrlArbitrationError.new(e)
  end

private

  def should_suppress?(error)
    ENV["SUPPRESS_DRAFT_STORE_502_ERROR"] && error.code == 502
  end

  def content_item_without_access_limiting
    @content_item_without_access_limiting ||= content_item.except(:access_limited)
  end

  def content_item_with_base_path
    content_item_without_access_limiting.merge(base_path: base_path)
  end
end
