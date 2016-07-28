module Commands
  module V2
    class PatchLinkSet < BaseCommand
      def call
        raise_unless_links_hash_is_provided

        link_set = LinkSet.find_by(content_id: content_id)

        if link_set
          check_version_and_raise_if_conflicting(link_set, previous_version_number)
          lock_version = LockVersion.find_by!(target: link_set)
        else
          link_set = LinkSet.create!(content_id: content_id)
          lock_version = LockVersion.new(target: link_set)
        end

        lock_version.increment
        lock_version.save!

        grouped_links.each do |group, payload_content_ids|
          links = link_set.links.where(link_type: group)
          existing_content_ids = links.pluck(:target_content_id)

          content_ids_to_create = payload_content_ids - existing_content_ids
          content_ids_to_delete = existing_content_ids - payload_content_ids

          content_ids_to_create.uniq.each do |content_id|
            links.create!(target_content_id: content_id)
          end

          content_ids_to_delete.each do |content_id|
            links.find_by!(target_content_id: content_id).destroy
          end
        end

        after_transaction_commit do
          send_downstream
        end

        presented = Presenters::Queries::LinkSetPresenter.present(link_set)
        Success.new(presented)
      end

    private

      def content_id
        payload.fetch(:content_id)
      end

      def grouped_links
        payload[:links]
      end

      def previous_version_number
        payload[:previous_version].to_i if payload[:previous_version]
      end

      def raise_unless_links_hash_is_provided
        unless grouped_links.is_a?(Hash)
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
          )
        end
      end

      def send_downstream
        return unless downstream

        filter = ContentItemFilter.new(scope: ContentItem.where(content_id: content_id))
        draft_content_item_ids = Queries::GetLatest.call(
          filter.filter(state: %w{draft published})).pluck(:id)
        draft_web_content_items = Queries::GetWebContentItems.(draft_content_item_ids)

        live_content_item_ids = filter.filter(state: "published").pluck(:id)
        live_web_content_items = Queries::GetWebContentItems.(live_content_item_ids)

        draft_web_content_items.each do |draft_web_content_item|
          send_to_content_store(draft_web_content_item, Adapters::DraftContentStore)
        end

        live_web_content_items.each do |live_web_content_item|
          downstream_publish(live_web_content_item)
        end
      end

      def bulk_publishing?
        payload.fetch(:bulk_publishing, false)
      end

      def downstream_publish(content_item)
        queue = bulk_publishing? ? DownstreamPublishWorker::LOW_QUEUE : DownstreamPublishWorker::HIGH_QUEUE
        DownstreamPublishWorker.perform_async_in_queue(
          queue,
          content_item_id: content_item.id,
          message_queue_update_type: "links",
          payload_version: event.id,
        )
      end

      def send_to_content_store(content_item, content_store)
        queue = bulk_publishing? ? PresentedContentStoreWorker::LOW_QUEUE : PresentedContentStoreWorker::HIGH_QUEUE
        PresentedContentStoreWorker.perform_async_in_queue(
          queue,
          content_store: content_store,
          payload: { content_item_id: content_item.id, payload_version: event.id },
        )
      end
    end
  end
end
