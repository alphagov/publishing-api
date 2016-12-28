module Commands
  module V2
    class PutContent < BaseCommand
      def call
        PutContentValidator.new(payload, self).validate
        prepare_content_with_base_path

        content_item = create_or_update_content_item
        update_content_dependencies(content_item)

        after_transaction_commit do
          send_downstream(content_item.content_id, locale)
        end

        Success.new(present_response(content_item))
      end

    private

      def content_with_base_path?
        base_path_required? || payload.has_key?(:base_path)
      end

      def prepare_content_with_base_path
        return unless content_with_base_path?
        PathReservation.reserve_base_path!(payload[:base_path], payload[:publishing_app])
        clear_draft_items_of_same_locale_and_base_path
      end

      def update_content_dependencies(content_item)
        create_redirect
        access_limit(content_item)
        update_last_edited_at(content_item, payload[:last_edited_at])
        ChangeNote.create_from_content_item(payload, content_item)
        Action.create_put_content_action(content_item, locale, event)
      end

      def create_redirect
        return unless content_with_base_path?
        RedirectHelper::Redirect.new(previously_published_item,
                                     @previous_item,
                                     payload, callbacks).create
      end


      def present_response(content_item)
        Presenters::Queries::ContentItemPresenter.present(
          content_item,
          include_warnings: true,
        )
      end

      def access_limit(content_item)
        if payload[:access_limited] && (users = payload[:access_limited][:users])
          AccessLimit.find_or_create_by(content_item: content_item).tap do |access_limit|
            access_limit.update_attributes!(users: users)
          end
        else
          AccessLimit.find_by(content_item: content_item).try(:destroy)
        end
      end

      def create_or_update_content_item
        if previously_drafted_item
          updated_item, @previous_item = UpdateExistingDraftContentItem.new(previously_drafted_item, self, payload).call
        else
          new_draft_content_item = CreateDraftContentItem.new(self, payload, previously_published_item).call
        end
        updated_item || new_draft_content_item
      end

      def previously_published_item
        @previously_published_item ||= PreviouslyPublishedItem.new(
          content_id, payload[:base_path], locale, self
        ).call
      end

      def base_path_required?
        !ContentItem::EMPTY_BASE_PATH_FORMATS.include?(payload[:schema_name])
      end

      def previously_drafted_item
        @previously_drafted_item ||= ContentItem.find_by(document: document, state: "draft")
      end

      def clear_draft_items_of_same_locale_and_base_path
        SubstitutionHelper.clear!(
          new_item_document_type: payload[:document_type],
          new_item_content_id: content_id,
          state: "draft",
          locale: locale,
          base_path: payload[:base_path],
          downstream: downstream,
          callbacks: callbacks,
          nested: true,
        )
      end

      def locale
        payload.fetch(:locale, ContentItem::DEFAULT_LOCALE)
      end

      def document
        Document.find_or_create_by(content_id: content_id, locale: locale)
      end

      def content_id
        payload.fetch(:content_id)
      end

      def update_last_edited_at(content_item, last_edited_at = nil)
        if last_edited_at.nil? && %w(major minor).include?(payload[:update_type])
          last_edited_at = Time.zone.now
        end

        content_item.update_attributes(last_edited_at: last_edited_at) if last_edited_at
      end

      def bulk_publishing?
        payload.fetch(:bulk_publishing, false)
      end

      def send_downstream(content_id, locale)
        return unless downstream

        queue = bulk_publishing? ? DownstreamDraftWorker::LOW_QUEUE : DownstreamDraftWorker::HIGH_QUEUE

        DownstreamDraftWorker.perform_async_in_queue(
          queue,
          content_id: content_id,
          locale: locale,
          payload_version: event.id,
          update_dependencies: true,
        )
      end
    end
  end
end
