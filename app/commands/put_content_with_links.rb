module Commands
  class PutContentWithLinks < BaseCommand
    def call
      if payload[:content_id]
        V2::PutContent.call(payload)
        V2::PutLinkSet.call(payload.slice(:content_id, :links))
        V2::Publish.call(payload)
      else
        base_path = payload.fetch(:base_path)

        PathReservation.reserve_base_path!(base_path, payload[:publishing_app])

        if downstream
          content_store_payload = Presenters::DownstreamPresenter::V1.present(
            payload.except(:access_limited),
            update_type: false
          )

          Adapters::DraftContentStore.put_content_item(base_path, content_store_payload)
          Adapters::ContentStore.put_content_item(base_path, content_store_payload)

          message_bus_payload = Presenters::DownstreamPresenter::V1.present(
            payload,
          )
          PublishingAPI.service(:queue_publisher).send_message(message_bus_payload)
        end
      end

      Success.new(payload.except(:base_path))
    end
  end
end
