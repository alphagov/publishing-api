module Commands
  class PutPublishIntent < BaseCommand
    def call
      PathReservation.reserve_base_path!(base_path, payload[:publishing_app])

      if downstream
        payload = Presenters::DownstreamPresenter::V1.present(
          publish_intent,
          event,
          payload_version: false
        )
        Adapters::ContentStore.put_publish_intent(base_path, payload)
      end

      Success.new(payload)
    end

  private

    def publish_intent
      payload.except(:base_path).deep_symbolize_keys
    end

    def base_path
      payload.fetch(:base_path)
    end
  end
end
