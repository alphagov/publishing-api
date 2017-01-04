module Commands
  module V2
    class PatchLinkSet < BaseCommand
      def call
        raise_unless_links_hash_is_provided
        validate_schema
        link_set = LinkSet.find_or_create_locked(content_id: content_id)

        check_version_and_raise_if_conflicting(link_set, previous_version_number)
        lock_version = LockVersion.find_or_create_by!(target: link_set)

        lock_version.increment
        lock_version.save!

        grouped_links.each do |group, payload_content_ids|
          # For each set of links in a LinkSet scoped by link_type, this iterator
          # deletes the entire existing set and then imports all the links in the
          # payload, preserving their ordering.
          link_set.links.where(link_type: group).delete_all

          payload_content_ids.uniq.each_with_index do |content_id, i|
            link_set.links.create!(target_content_id: content_id, link_type: group, position: i)
          end
        end

        after_transaction_commit do
          send_downstream
        end

        Action.create_patch_link_set_action(link_set, event)

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

        draft_locales = Queries::LocalesForContentItems.call([content_id], %w[draft live])
        draft_locales.each { |(content_id, locale)| downstream_draft(content_id, locale) }

        live_locales = Queries::LocalesForContentItems.call([content_id], %w[live])
        live_locales.each { |(content_id, locale)| downstream_live(content_id, locale) }
      end

      def bulk_publishing?
        payload.fetch(:bulk_publishing, false)
      end

      def downstream_draft(content_id, locale)
        queue = bulk_publishing? ? DownstreamDraftWorker::LOW_QUEUE : DownstreamDraftWorker::HIGH_QUEUE
        DownstreamDraftWorker.perform_async_in_queue(
          queue,
          content_id: content_id,
          locale: locale,
          payload_version: event.id,
        )
      end

      def downstream_live(content_id, locale)
        queue = bulk_publishing? ? DownstreamLiveWorker::LOW_QUEUE : DownstreamLiveWorker::HIGH_QUEUE
        DownstreamLiveWorker.perform_async_in_queue(
          queue,
          content_id: content_id,
          locale: locale,
          message_queue_update_type: "links",
          payload_version: event.id,
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
          ContentItem.where(documents: { content_id: content_id })
        ).pluck(:schema_name).first
      end
    end
  end
end
