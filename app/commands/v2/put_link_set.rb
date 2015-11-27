module Commands
  module V2
    class PutLinkSet < BaseCommand
      def call
        validate!

        link_set = LinkSet.create_or_replace(link_params.except(:links)) do |link_set|
          version = Version.find_or_initialize_by(target: link_set)
          version.increment
          version.save! if link_set.valid?

          links_hash = link_params.fetch(:links)

          links_hash.each do |link_type, target_content_ids|
            if target_content_ids.empty?
              link_set.links.where(link_type: link_type).delete_all
            else
              old_target_ids = link_set.links.where(link_type: link_type).pluck(:target_content_id)

              ids_to_be_deleted = old_target_ids - target_content_ids
              link_set.links.where(link_type: link_type, target_content_id: ids_to_be_deleted).delete_all

              ids_to_be_created = target_content_ids - old_target_ids
              ids_to_be_created.each do |target_content_id|
                link_set.links.create!(link_type: link_type, target_content_id: target_content_id)
              end
            end
          end
        end

        if (draft_content_item = DraftContentItem.find_by(content_id: link_params.fetch(:content_id)))
          draft_payload = Presenters::ContentStorePresenter.present(draft_content_item)
          ContentStoreWorker.perform_async(
            content_store: Adapters::DraftContentStore,
            base_path: draft_content_item.base_path,
            payload: draft_payload,
          )
        end

        if (live_content_item = LiveContentItem.find_by(content_id: link_params.fetch(:content_id)))
          live_payload = Presenters::ContentStorePresenter.present(live_content_item)
          ContentStoreWorker.perform_async(
            content_store: Adapters::ContentStore,
            base_path: live_content_item.base_path,
            payload: live_payload,
          )

          queue_payload = Presenters::MessageQueuePresenter.present(live_content_item, update_type: "links")
          PublishingAPI.service(:queue_publisher).send_message(queue_payload)
        end

        presented = Presenters::Queries::LinkSetPresenter.new(link_set).present
        Success.new(presented)
      end

    private
      def validate!
        validate_links!
        validate_version_lock!
      end

      def validate_links!
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

      def validate_version_lock!
        super(LinkSet, link_params.fetch(:content_id), payload[:previous_version])
      end

      def link_params
        payload.except(:previous_version)
      end

      def merge_links(base_links, new_links)
        base_links
          .merge(new_links)
          .reject {|_, links| links.empty? }
      end
    end
  end
end
