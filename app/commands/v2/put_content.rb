module Commands
  module V2
    class PutContent < BaseCommand
      def call
        validate
        prepare_content_with_base_path

        content_item = find_or_create_content_item
        update_content_dependencies(content_item)

        after_transaction_commit do
          send_downstream(content_item.content_id, locale)
        end

        Success.new(
          response_hash(content_item)
        )
      end

      def content_with_base_path?
        base_path_required? || payload.has_key?(:base_path)
      end

    private

      def prepare_content_with_base_path
        return unless content_with_base_path?
        PathReservation.reserve_base_path!(payload[:base_path], publishing_app)
        clear_draft_items_of_same_locale_and_base_path
      end

      def update_content_dependencies(content_item)
        access_limit(content_item)
        update_last_edited_at_if_needed(content_item, payload[:last_edited_at])
        ChangeNote.create_from_content_item(payload, content_item)
        Action.create_put_content_action(content_item, locale, event)
      end

      def validate
        raise_if_links_are_provided
        validate_schema

        if publishing_app.blank?
          raise_command_error(422, "publishing_app is required", fields: {
            publishing_app: ["is required"]
          })
        end

      end

      def response_hash(content_item)
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

      def find_or_create_content_item
        content_item = find_previously_drafted_content_item

        if content_item
          UpdateExistingDraftContentItem.new(content_item, self, payload).call
        else
          content_item = CreateDraftContentItem.new(self, payload).call
        end
        content_item
      end

      def base_path_required?
        !ContentItem::EMPTY_BASE_PATH_FORMATS.include?(payload[:schema_name])
      end

      def find_previously_drafted_content_item
        ContentItem.find_by(
          id: pessimistic_content_item_scope.pluck(:id),
          state: "draft",
        )
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

      def pessimistic_content_item_scope
        ContentItem.where(content_id: content_id, locale: locale).lock
      end

      def content_id
        payload.fetch(:content_id)
      end

      def publishing_app
        payload[:publishing_app]
      end

      def update_last_edited_at_if_needed(content_item, last_edited_at = nil)
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

      def raise_if_links_are_provided
        return unless payload.has_key?(:links)
        message = "The 'links' parameter should not be provided to this endpoint."

        raise CommandError.new(
          code: 400,
          message: message,
          error_details: {
            error: {
              code: 400,
              message: message,
              fields: {
                links: ["is not a valid parameter"],
              }
            }
          }
        )
      end

      def validate_schema
        return if schema_validator.valid?
        message = "The payload did not conform to the schema"
        raise CommandError.new(
          code: 422,
          message: message,
          error_details: schema_validator.errors,
        )
      end

      def schema_validator
        @schema_validator ||= SchemaValidator.new(payload: payload.except(:content_id))
      end
    end
  end
end
