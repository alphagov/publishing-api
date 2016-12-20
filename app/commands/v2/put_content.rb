module Commands
  module V2
    class PutContent < BaseCommand
      ITEM_NOT_FOUND = Class.new
      def call
        raise_if_links_is_provided
        validate_schema

        if publishing_app.blank?
          raise_command_error(422, "publishing_app is required", fields: {
            publishing_app: ["is required"]
          })
        end

        PathReservation.reserve_base_path!(base_path, publishing_app) if content_with_base_path?
        content_item = find_previously_drafted_content_item

        if content_item
          update_existing_content_item(content_item)
        else
          clear_draft_items_of_same_locale_and_base_path if content_with_base_path?

          content_item = create_content_item
          fill_out_new_content_item(content_item)
        end

        ChangeNote.create_from_content_item(payload, content_item)

        after_transaction_commit do
          send_downstream(content_item.content_id, locale)
        end

        response_hash = Presenters::Queries::ContentItemPresenter.present(
          content_item,
          include_warnings: true,
        )

        Action.create_put_content_action(content_item, locale, event)
        Success.new(response_hash)
      end

    private

      def fill_out_new_content_item(content_item)
        create_supporting_objects(content_item)
        ensure_link_set_exists(content_item)

        update_last_edited_at_if_needed(content_item, payload[:last_edited_at])

        if previously_published_item != ITEM_NOT_FOUND
          set_first_published_at(content_item, previously_published_item)

          previous_base_path = previously_published_item.base_path
          previous_routes = previously_published_item.routes

          if path_has_changed?(previous_base_path)
            create_redirect(
              from_path: previous_base_path,
              to_path: base_path,
              routes: previous_routes,
            )
          end
        end

        if payload[:access_limited] && (users = payload[:access_limited][:users])
          AccessLimit.create!(content_item: content_item, users: users)
        end
      end

      def update_existing_content_item(content_item)
        version = check_version_and_raise_if_conflicting(content_item, payload[:previous_version])

        if content_with_base_path?
          clear_draft_items_of_same_locale_and_base_path

          previous_base_path = content_item.base_path
          previous_routes = content_item.routes
        end

        update_content_item(content_item)
        update_last_edited_at_if_needed(content_item, payload[:last_edited_at])

        increment_lock_version(version)

        if path_has_changed?(previous_base_path)
          create_redirect(
            from_path: previous_base_path,
            to_path: base_path,
            routes: previous_routes,
          )
        end

        if payload[:access_limited] && (users = payload[:access_limited][:users])
          create_or_update_access_limit(content_item, users: users)
        else
          AccessLimit.find_by(content_item: content_item).try(:destroy)
        end
      end

      def create_or_update_access_limit(content_item, users:)
        if (access_limit = AccessLimit.find_by(content_item: content_item))
          access_limit.update_attributes!(users: users)
        else
          AccessLimit.create!(content_item: content_item, users: users)
        end
      end

      def find_previously_drafted_content_item
        ContentItem.where(
          id: pessimistic_content_item_scope.pluck(:id),
          state: "draft",
        ).first
      end

      def clear_draft_items_of_same_locale_and_base_path
        SubstitutionHelper.clear!(
          new_item_document_type: document_type,
          new_item_content_id: content_id,
          state: "draft",
          locale: locale,
          base_path: base_path,
          downstream: downstream,
          callbacks: callbacks,
          nested: true,
        )
      end

      def content_item_attributes_from_payload
        payload.slice(*ContentItem::TOP_LEVEL_FIELDS)
      end

      def create_content_item
        attributes = content_item_attributes_from_payload.merge(
          locale: locale,
          state: "draft",
          user_facing_version: user_facing_version_number_for_new_draft,
        )
        ContentItem.create!(attributes)
      end

      def create_supporting_objects(content_item)
        LockVersion.create!(target: content_item, number: lock_version_number_for_new_draft)
      end

      def ensure_link_set_exists(content_item)
        existing_link_set = LinkSet.find_by(content_id: content_item.content_id)
        return if existing_link_set

        link_set = LinkSet.create!(content_id: content_item.content_id)
        LockVersion.create!(target: link_set, number: 1)
      end

      def lock_version_number_for_new_draft
        if previously_published_item != ITEM_NOT_FOUND
          lock_version = LockVersion.find_by!(target: previously_published_item)
          lock_version.number + 1
        else
          1
        end
      end

      def user_facing_version_number_for_new_draft
        if previously_published_item != ITEM_NOT_FOUND
          previously_published_item.user_facing_version + 1
        else
          1
        end
      end

      def pessimistic_content_item_scope
        ContentItem.where(content_id: content_id, locale: locale).lock
      end

      def previously_published_item
        @previously_published_item ||=
          ContentItem.where(
            content_id: content_id,
            state: %w(published unpublished),
            locale: locale,
          ).order(user_facing_version: :desc).first || ITEM_NOT_FOUND
      end

      def set_first_published_at(content_item, previously_published_item)
        if content_item.first_published_at.nil?
          content_item.update_attributes(
            first_published_at: previously_published_item.first_published_at,
          )
        end
      end

      def path_has_changed?(previous_base_path)
        return false unless content_with_base_path?
        previous_base_path != base_path
      end

      def content_id
        payload.fetch(:content_id)
      end

      def document_type
        payload[:document_type]
      end

      def base_path
        payload[:base_path]
      end

      def content_with_base_path?
        base_path_required? || payload.has_key?(:base_path)
      end

      def base_path_required?
        !ContentItem::EMPTY_BASE_PATH_FORMATS.include?(payload[:schema_name])
      end

      def locale
        payload.fetch(:locale, ContentItem::DEFAULT_LOCALE)
      end

      def publishing_app
        payload[:publishing_app]
      end

      def update_content_item(content_item)
        content_item.assign_attributes_with_defaults(
          content_item_attributes_from_payload.merge(
            locale: locale,
            state: "draft",
            user_facing_version: content_item.user_facing_version,
          )
        )
        content_item.save!
      end

      def update_last_edited_at_if_needed(content_item, last_edited_at = nil)
        if last_edited_at.nil? && %w(major minor).include?(payload[:update_type])
          last_edited_at = Time.zone.now
        end

        content_item.update_attributes(last_edited_at: last_edited_at) if last_edited_at
      end

      def increment_lock_version(lock_version)
        lock_version.increment
        lock_version.save!
      end

      def create_redirect(from_path:, to_path:, routes:)
        RedirectHelper.create_redirect(
          publishing_app: publishing_app,
          old_base_path: from_path,
          new_base_path: to_path,
          routes: routes,
          callbacks: callbacks,
        )
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

      def raise_if_links_is_provided
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
