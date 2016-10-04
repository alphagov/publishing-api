module Commands
  class PutContentWithLinks < BaseCommand
    def call
      if payload[:content_id]
        V2::PutContent.call(v2_put_content_payload, downstream: downstream, callbacks: callbacks, nested: true)
        V2::PatchLinkSet.call(v2_put_link_set_payload, downstream: downstream, callbacks: callbacks, nested: true)
        V2::Publish.call(v2_publish_payload, downstream: downstream, callbacks: callbacks, nested: true)
      else
        base_path = payload.fetch(:base_path)

        PathReservation.reserve_base_path!(base_path, payload[:publishing_app])

        if downstream
          content_store_payload = Presenters::DownstreamPresenter::V1.present(
            payload.except(:access_limited),
            event,
            update_type: false
          )

          Adapters::DraftContentStore.put_content_item(base_path, content_store_payload)
          Adapters::ContentStore.put_content_item(base_path, content_store_payload)

          message_bus_payload = Presenters::DownstreamPresenter::V1.present(
            payload.except(:access_limited),
            event,
          )
          PublishingAPI.service(:queue_publisher).send_message(message_bus_payload)
        end
      end

      Success.new(payload)
    end

    def v2_put_content_payload
      payload
        .except(:access_limited, :links)
    end

    def v2_put_link_set_payload
      payload
        .slice(:content_id, :links)
        .merge(links: payload[:links] || {})
    end

    def v2_publish_payload
      payload
        .except(:access_limited)
        .merge(update_type: payload[:update_type] || "major")
    end
  end
end
