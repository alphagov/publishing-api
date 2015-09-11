class Command::PutDraftContentWithLinks < Command::BaseCommand
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
end
