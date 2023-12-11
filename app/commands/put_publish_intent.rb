module Commands
  class PutPublishIntent < BaseCommand
    def call
      PathReservation.reserve_base_path!(base_path, payload[:publishing_app])

      if downstream
        payload = publish_intent
        enqueue = ENV.fetch("ENQUEUE_PUBLISH_INTENTS", false)
        if enqueue == "true"
          PutPublishIntentWorker.perform_async(
            "base_path" => base_path,
            "payload" => payload.to_json,
          )
        else
          Adapters::ContentStore.put_publish_intent(base_path, payload)
        end
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
