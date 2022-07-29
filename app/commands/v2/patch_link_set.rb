module Commands
  module V2
    class PatchLinkSet < BaseCommand
      def call
        raise_unless_links_hash_is_provided
        validate_schema
        link_set = LinkSet.find_or_create_locked(content_id:)
        check_version_and_raise_if_conflicting(link_set, previous_version_number)

        link_set.increment!(:stale_lock_version)

        before_links = link_set.links.to_a

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

        orphaned_content_ids = link_diff_between(before_links.map(&:target_content_id), link_set.links.map(&:target_content_id))
        update_dependencies = link_set.links_changed?(before_links)

        after_transaction_commit do
          send_downstream(orphaned_content_ids, update_dependencies)
        end

        Action.create_patch_link_set_action(link_set, before_links, event)

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
                },
              },
            },
          )
        end
      end

      def send_downstream(orphaned_content_ids, update_dependencies)
        return unless downstream

        draft_locales = Queries::LocalesForEditions.call([content_id], %w[draft live])
        draft_locales.each do |(content_id, locale)|
          downstream_draft(content_id, locale, orphaned_content_ids, update_dependencies)
        end

        live_locales = Queries::LocalesForEditions.call([content_id], %w[live])
        live_locales.each do |(content_id, locale)|
          downstream_live(content_id, locale, orphaned_content_ids, update_dependencies)
        end
      end

      def bulk_publishing?
        payload.fetch(:bulk_publishing, false)
      end

      def downstream_draft(content_id, locale, orphaned_content_ids, update_dependencies)
        queue = bulk_publishing? ? DownstreamDraftWorker::LOW_QUEUE : DownstreamDraftWorker::HIGH_QUEUE
        DownstreamDraftWorker.perform_async_in_queue(
          queue,
          content_id:,
          locale:,
          orphaned_content_ids:,
          update_dependencies:,
          source_command: "patch_link_set",
        )
      end

      def downstream_live(content_id, locale, orphaned_content_ids, update_dependencies)
        queue = bulk_publishing? ? DownstreamLiveWorker::LOW_QUEUE : DownstreamLiveWorker::HIGH_QUEUE
        DownstreamLiveWorker.perform_async_in_queue(
          queue,
          content_id:,
          locale:,
          message_queue_event_type: "links",
          orphaned_content_ids:,
          update_dependencies:,
          source_command: "patch_link_set",
        )
      end

      def validate_schema
        # We allow setting links before the document actually exists.
        # This means we blindly accept anything regardless of what the schema says.
        return true unless schema_name

        unless schema_validator.valid?
          # Do not raise anything yet, only report a warning.
          # This should be changed to an error once this message no longer
          # shows up in the logs.
          Rails.logger.warn("#{content_id} links do not conform to <#{schema_name}> schema: #{schema_validator.errors}")
        end
      end

      def schema_validator
        @schema_validator ||= SchemaValidator.new(
          payload: { links: payload[:links] },
          schema_name:,
          schema_type: :links,
        )
      end

      def schema_name
        @schema_name ||= Queries::GetLatest.call(
          Edition.with_document.where("documents.content_id": content_id),
        ).pick(:schema_name)
      end
    end
  end
end
