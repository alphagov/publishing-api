module Commands
  module V2
    class PutLinkSet < BaseCommand
      def call
        validate!

        link_set = LinkSet.create_or_replace(link_params.except(:links)) do |link_set|
          version = Version.find_or_initialize_by(target: link_set)
          version.increment
          version.save! if link_set.valid?

          link_set.links = merge_links(link_set.links, link_params.fetch(:links))
        end

        if (draft_content_item = DraftContentItem.find_by(content_id: link_params.fetch(:content_id)))
          Adapters::DraftContentStore.call(draft_content_item.base_path, draft_content_store_payload(draft_content_item))
        end

        if (live_content_item = LiveContentItem.find_by(content_id: link_params.fetch(:content_id)))
          Adapters::ContentStore.call(live_content_item.base_path, live_content_store_payload(live_content_item))
          PublishingAPI.service(:queue_publisher).send_message(message_bus_payload(live_content_item))
        end

        create_or_update_content_item_links!

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

      def draft_content_store_payload(content_item)
        content_item_fields = DraftContentItem::TOP_LEVEL_FIELDS + [:links]
        draft_item_hash = LinkSetMerger.merge_links_into(content_item)
          .slice(*content_item_fields)

        Presenters::ContentItemPresenter.present(draft_item_hash)
      end

      def live_content_store_payload(content_item)
        content_item_fields = LiveContentItem::TOP_LEVEL_FIELDS + [:links]
        live_item_hash = LinkSetMerger.merge_links_into(content_item)
          .slice(*content_item_fields)

        Presenters::ContentItemPresenter.present(live_item_hash)
      end

      def message_bus_payload(content_item)
        live_content_store_payload(content_item).merge(update_type: "links")
      end

      def create_or_update_content_item_links!
        ContentItemLinkPopulator.create_or_replace(link_params[:content_id], link_params[:links])
      end
    end
  end
end
