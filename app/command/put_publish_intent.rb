class Command::PutPublishIntent < Command::BaseCommand
  def call
    Adapters::UrlArbiter.new(services: services).call(base_path, payload[:publishing_app])

    publish_intent = payload.except(:base_path).deep_symbolize_keys

    services.service(:live_content_store).put_publish_intent(
      base_path: base_path,
      publish_intent: publish_intent
    )

    Command::Success.new(publish_intent)
  end
end
