module Commands
  module V2
    class PutContent < BaseCommand
      def call
        PutContentValidator.new(payload, self).validate

        prepare_content_with_base_path
        check_update_type

        edition = create_or_update_edition
        set_timestamps(edition)

        update_content_dependencies(edition)

        orphaned_links = link_diff_between(
          @links_before_update,
          edition.links.map(&:target_content_id)
        )

        after_transaction_commit do
          send_downstream(
            document.content_id,
            document.locale,
            edition,
            orphaned_links
          )
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

      def prepare_content_with_base_path
        return unless payload[:base_path]

        PathReservation.reserve_base_path!(payload[:base_path], payload[:publishing_app])
        clear_draft_items_of_same_locale_and_base_path
      end

      def update_content_dependencies(edition)
        create_redirect
        access_limit(edition)
        ChangeNote.create_from_edition(payload, edition)
        create_links(edition)
        Action.create_put_content_action(edition, document.locale, event)
      end

      def set_timestamps(edition)
        Edition::Timestamps.edited(edition, payload, previously_published_edition)
      end

      def check_update_type
        return unless payload[:update_type].blank?

        GovukError.notify(
          "#{payload[:publishing_app]} sent put content without providing an update_type",
          level: "warning",
          extra: payload.slice(:publishing_app, :content_id, :locale),
        )
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
        return unless payload[:base_path]

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
              organisations: (payload[:access_limited][:organisations] || []),
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

      def bulk_publishing?
        payload.fetch(:bulk_publishing, false)
      end

      def update_dependencies?(edition)
        LinkExpansion::EditionDiff.new(edition, previous_edition: @previous_edition).should_update_dependencies?
      end

      def send_downstream(content_id, locale, edition, orphaned_links)
        return unless downstream

        queue = bulk_publishing? ? DownstreamDraftWorker::LOW_QUEUE : DownstreamDraftWorker::HIGH_QUEUE

        DownstreamDraftWorker.perform_async_in_queue(
          queue,
          content_id: content_id,
          locale: locale,
          update_dependencies: update_dependencies?(edition),
          orphaned_content_ids: orphaned_links,
          source_command: "put_content",
        )
      end
    end
  end
end
