module Commands
  class PutPublishIntent < BaseCommand
    def call
      PathReservation.reserve_base_path!(base_path, payload[:publishing_app])

      payload = Presenters::ContentStorePresenter::V1.present(publish_intent, transmitted_at: false)

      PublishingAPI.service(:live_content_store).put_publish_intent(
        base_path: base_path,
        publish_intent: payload
      )

      Success.new(payload)
    end

  private
    def publish_intent
      payload.except(:base_path).deep_symbolize_keys
    end
  end
end
