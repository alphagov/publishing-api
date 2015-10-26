module Commands
  class PutPublishIntent < BaseCommand
    def call
      PathReservation.reserve_base_path!(base_path, payload[:publishing_app])

      publish_intent = payload.except(:base_path).deep_symbolize_keys

      PublishingAPI.service(:live_content_store).put_publish_intent(
        base_path: base_path,
        publish_intent: publish_intent
      )

      Success.new(publish_intent)
    end
  end
end
