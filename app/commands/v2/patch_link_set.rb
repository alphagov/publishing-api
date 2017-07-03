module Commands
  module V2
    class PatchLinkSet < BaseCommand
      def call
        raise_unless_links_hash_is_provided
        validate_schema
        link_set = LinkSet.find_or_create_locked(content_id: content_id)
        check_version_and_raise_if_conflicting(link_set, previous_version_number)

        link_set.increment!(:stale_lock_version)

        links_before_patch = link_set.links.map(&:target_content_id)

        grouped_links.each do |group, payload_content_ids|
          # For each set of links in a LinkSet scoped by link_type, this iterator
          # deletes the entire existing set and then imports all the links in the
          # payload, preserving their ordering.
          link_set.links.where(link_type: group).delete_all

          payload_content_ids.uniq.each_with_index do |content_id, i|
            link_set.links.create!(target_content_id: content_id, link_type: group, position: i)
          end
        end

        # we need to reload the link_set as the links association will be stale
        link_set.reload

        orphaned_content_ids = link_diff_between(links_before_patch, link_set.links.map(&:target_content_id))

        after_transaction_commit do
          send_downstream(orphaned_content_ids)
          ExpandedLinkSetCacheWorker.perform_async(content_id)
        end

        Action.create_patch_link_set_action(link_set, event)

        presented = Presenters::Queries::LinkSetPresenter.present(link_set)
        Success.new(presented)
      end

    private

      def link_diff_between(links_before_patch, links_after_patch)
        links_before_patch - links_after_patch
      end

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

      def send_downstream(orphaned_content_ids)
        return unless downstream

        draft_locales = Queries::LocalesForEditions.call([content_id], %w[draft live])
        draft_locales.each { |(content_id, locale)| downstream_draft(content_id, locale, orphaned_content_ids) }

        live_locales = Queries::LocalesForEditions.call([content_id], %w[live])
        live_locales.each { |(content_id, locale)| downstream_live(content_id, locale, orphaned_content_ids) }
      end

      def bulk_publishing?
        payload.fetch(:bulk_publishing, false)
      end

      def downstream_draft(content_id, locale, orphaned_content_ids)
        queue = bulk_publishing? ? DownstreamDraftWorker::LOW_QUEUE : DownstreamDraftWorker::HIGH_QUEUE
        DownstreamDraftWorker.perform_async_in_queue(
          queue,
          content_id: content_id,
          locale: locale,
          payload_version: event.id,
          orphaned_content_ids: orphaned_content_ids,
        )
      end

      def downstream_live(content_id, locale, orphaned_content_ids)
        queue = bulk_publishing? ? DownstreamLiveWorker::LOW_QUEUE : DownstreamLiveWorker::HIGH_QUEUE
        DownstreamLiveWorker.perform_async_in_queue(
          queue,
          content_id: content_id,
          locale: locale,
          message_queue_update_type: "links",
          payload_version: event.id,
          orphaned_content_ids: orphaned_content_ids,
        )
      end

      def validate_schema
        # There may not be a ContentItem yet.
        return true unless schema_name

        # Do not raise anything yet
        # Only send errbit notification
        schema_validator.valid?
      end

      def schema_validator
        @schema_validator ||= SchemaValidator.new(
          payload: payload[:links],
          links: true,
          schema_name: schema_name
        )
      end

      def schema_name
        @schema_name ||= Queries::GetLatest.(
          Edition.with_document.where("documents.content_id": content_id)
        ).pluck(:schema_name).first
      end
    end
  end
end
