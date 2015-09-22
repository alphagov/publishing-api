class Command::DeletePublishIntent < Command::BaseCommand
  def call
    services.service(:live_content_store).delete_publish_intent(base_path)

    Command::Success.new({})
  rescue GdsApi::HTTPServerError => e
    raise Command::Error.new(code: e.code, message: e.message)
  rescue GdsApi::HTTPClientError => e
    raise Command::Error.new(code: e.code, error_details: e.error_details)
  rescue GdsApi::BaseError => e
    raise Command::Error.new(code: 500, message: "Unexpected error from content store: #{e.message}")
  end
end
