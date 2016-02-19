module Commands
  class PutContentWithLinks < BaseCommand
    def call
      add_update_type_if_not_provided
      add_links_if_not_provided

      if payload[:content_id]
        V2::PutContent.call(payload.except(:access_limited), downstream: downstream)
        V2::PutLinkSet.call(payload.slice(:content_id, :links), downstream: downstream)
        V2::Publish.call(payload.except(:access_limited), downstream: downstream)
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
            payload.except(:access_limited),
          )
          PublishingAPI.service(:queue_publisher).send_message(message_bus_payload)
        end
      end

      Success.new(payload)
    end

    def add_update_type_if_not_provided
      return if payload[:update_type].present?
      payload[:update_type] = "major"
    end

    def add_links_if_not_provided
      return if payload[:links].present?
      payload[:links] = {}
    end
  end
end
