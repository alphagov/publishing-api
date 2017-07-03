module Commands
  module V2
    class PutContent < BaseCommand
      def call
        PutContentValidator.new(payload, self).validate
        prepare_content_with_base_path

        edition = create_or_update_edition

        update_content_dependencies(edition)

        orphaned_links = link_diff_between(
          @links_before_update,
          edition.links.map(&:target_content_id)
        )

        after_transaction_commit do
          send_downstream(
            document.content_id,
            document.locale,
            update_dependencies?(edition),
            orphaned_links
          )

          unless payload[:links].nil?
            ExpandedLinkSetCacheWorker.perform_async(document.content_id)
          end
        end

        Success.new(present_response(edition))
      end

      def document
        @document ||= Document.find_or_create_locked(
          content_id: payload.fetch(:content_id),
          locale: payload.fetch(:locale, Edition::DEFAULT_LOCALE),
        )
      end

    private

      def link_diff_between(old_links, new_links)
        old_links - new_links
      end

      def content_with_base_path?
        base_path_required? || payload.has_key?(:base_path)
      end

      def prepare_content_with_base_path
        return unless content_with_base_path?
        PathReservation.reserve_base_path!(payload[:base_path], payload[:publishing_app])
        clear_draft_items_of_same_locale_and_base_path
      end

      def update_content_dependencies(edition)
        create_redirect
        access_limit(edition)
        update_last_edited_at(edition, payload[:last_edited_at])
        ChangeNote.create_from_edition(payload, edition)
        Action.create_put_content_action(edition, document.locale, event)
        create_links(edition)
      end

      def create_links(edition)
        return if payload[:links].nil?
        payload[:links].each do |link_type, target_link_ids|
          edition.links.create!(
            target_link_ids.map.with_index do |target_link_id, i|
              { link_type: link_type, target_content_id: target_link_id, position: i }
            end
          )
        end
      end

      def create_redirect
        return unless content_with_base_path?
        RedirectHelper::Redirect.new(previously_published_edition,
                                     @previous_edition,
                                     payload, callbacks).create
      end

      def present_response(edition)
        Presenters::Queries::ContentItemPresenter.present(
          edition,
          include_warnings: true,
        )
      end

      def access_limit(edition)
        if payload[:access_limited]
          AccessLimit.find_or_create_by(edition: edition).tap do |access_limit|
            access_limit.update_attributes!(
              users: (payload[:access_limited][:users] || []),
              auth_bypass_ids: (payload[:access_limited][:auth_bypass_ids] || []),
            )
          end
        else
          AccessLimit.find_by(edition: edition).try(:destroy)
        end
      end

      def create_or_update_edition
        if previous_drafted_edition
          @links_before_update = previous_drafted_edition.links.map(&:target_content_id)
          updated_item, @previous_edition = UpdateExistingDraftEdition.new(previous_drafted_edition, self, payload).call
        else
          @links_before_update = previously_published_edition.links.map(&:target_content_id)
          new_draft_edition = CreateDraftEdition.new(self, payload, previously_published_edition).call
        end
        updated_item || new_draft_edition
      end

      def previously_published_edition
        @previously_published_edition ||= PreviouslyPublishedItem.new(
          document, payload[:base_path], self
        ).call
      end

      def base_path_required?
        !Edition::EMPTY_BASE_PATH_FORMATS.include?(payload[:schema_name])
      end

      def previous_drafted_edition
        document.draft
      end

      def clear_draft_items_of_same_locale_and_base_path
        SubstitutionHelper.clear!(
          new_item_document_type: payload[:document_type],
          new_item_content_id: document.content_id,
          state: "draft",
          locale: document.locale,
          base_path: payload[:base_path],
          downstream: downstream,
          callbacks: callbacks,
          nested: true,
        )
      end

      def update_last_edited_at(edition, last_edited_at = nil)
        if last_edited_at.nil? && %w(major minor).include?(payload[:update_type])
          last_edited_at = Time.zone.now
        end

        edition.update_attributes(last_edited_at: last_edited_at) if last_edited_at
      end

      def bulk_publishing?
        payload.fetch(:bulk_publishing, false)
      end

      def update_dependencies?(edition)
        EditionDiff.new(edition, previous_edition: @previous_edition).field_diff.present?
      end

      def send_downstream(content_id, locale, update_dependencies, orphaned_links)
        return unless downstream

        queue = bulk_publishing? ? DownstreamDraftWorker::LOW_QUEUE : DownstreamDraftWorker::HIGH_QUEUE

        DownstreamDraftWorker.perform_async_in_queue(
          queue,
          content_id: content_id,
          locale: locale,
          payload_version: event.id,
          update_dependencies: update_dependencies,
          orphaned_content_ids: orphaned_links,
        )
      end
    end
  end
end
