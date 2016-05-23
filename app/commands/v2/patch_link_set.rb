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

      def locale
        payload.fetch(:locale, ContentItem::DEFAULT_LOCALE)
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
        draft_content_item = filter.filter(state: "draft", locale: locale).first
        live_content_item = filter.filter(state: "published", locale: locale).first

        if draft_content_item
          send_to_content_store(draft_content_item, Adapters::DraftContentStore)
        end

        if live_content_item
          send_to_content_store(live_content_item, Adapters::ContentStore)
          send_to_message_queue(live_content_item)
        end
      end

      def send_to_content_store(content_item, content_store)
        PresentedContentStoreWorker.perform_async(
          content_store: content_store,
          payload: { content_item_id: content_item.id, payload_version: event.id },
          request_uuid: GdsApi::GovukHeaders.headers[:govuk_request_id],
        )
      end

      def send_to_message_queue(content_item)
        payload = Presenters::MessageQueuePresenter.present(
          content_item,
          state_fallback_order: [:published],
          update_type: "links",
        )

        PublishingAPI.service(:queue_publisher).send_message(payload)
      end
    end
  end
end
