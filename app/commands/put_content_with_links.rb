module Commands
  class PutContentWithLinks < BaseCommand
    def call
      if payload[:content_id]
        delete_existing_links

        V2::PutContent.call(v2_put_content_payload, downstream: downstream)
        V2::PatchLinkSet.call(v2_put_link_set_payload, downstream: downstream)
        V2::Publish.call(v2_publish_payload, downstream: downstream)
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

    def delete_existing_links
      link_set = LinkSet.find_by(content_id: payload[:content_id])
      return unless link_set

      links = link_set.links.where.not(link_type: protected_link_types)
      links.destroy_all
    end

    def protected_link_types
      ["alpha_taxons"]
    end
  end
end
