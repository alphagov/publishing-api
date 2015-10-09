class Commands::DeletePublishIntent < Commands::BaseCommand
  def call
    PublishingAPI.service(:live_content_store).delete_publish_intent(base_path)

    Commands::Success.new({})
  rescue GdsApi::HTTPServerError => e
    raise CommandError.new(code: e.code, message: e.message)
  rescue GdsApi::HTTPClientError => e
    raise CommandError.new(code: e.code, error_details: e.error_details)
  rescue GdsApi::BaseError => e
    raise CommandError.new(code: 500, message: "Unexpected error from content store: #{e.message}")
  end
end
