module Commands
  module V2
    class PutLinkSet < BaseCommand
      def call
        validate!

        link_set = LinkSet.create_or_replace(link_params.except(:links)) do |link_set|
          version = Version.find_or_initialize_by(target: link_set)
          version.increment
          version.save!

          link_set.links = merge_links(link_set.links, link_params.fetch(:links))
        end

        if (draft_content_item = DraftContentItem.find_by(content_id: link_params.fetch(:content_id)))
          Adapters::DraftContentStore.call(draft_content_item.base_path, content_store_payload(draft_content_item))
        end

        if (live_content_item = LiveContentItem.find_by(content_id: link_params.fetch(:content_id)))
          Adapters::ContentStore.call(live_content_item.base_path, content_store_payload(live_content_item))
          PublishingAPI.service(:queue_publisher).send_message(message_bus_payload(live_content_item))
        end

        Success.new(links: link_set.links)
      end

    private
      def validate!
        raise CommandError.new(
          code: 422,
          message: "Links are required",
          error_details: {
            error: {
              code: 422,
              message: "Links are required",
              fields: {
                links: ["are required"],
              }
            }
          }
        ) unless link_params[:links].present?
      end

      def link_params
        payload
      end

      def merge_links(base_links, new_links)
        base_links
          .merge(new_links)
          .reject {|_, links| links.empty? }
      end

      def content_store_payload(content_item)
        content_item_hash = LinkSetMerger.merge_links_into(content_item)
        Presenters::ContentItemPresenter.present(content_item_hash)
      end

      def message_bus_payload(content_item)
        content_store_payload(content_item).merge(update_type: "links")
      end
    end
  end
end
