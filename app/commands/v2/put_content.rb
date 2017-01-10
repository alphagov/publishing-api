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
        edition = document.draft

        if edition
          update_existing_edition(edition)
        else
          clear_draft_items_of_same_locale_and_base_path if content_with_base_path?

          edition = create_edition
          fill_out_new_edition(edition)
        end

        ChangeNote.create_from_edition(payload, edition)

        after_transaction_commit do
          send_downstream(edition.content_id, document.locale)
        end

        response_hash = Presenters::Queries::EditionPresenter.present(
          edition,
          include_warnings: true,
        )

        Action.create_put_content_action(edition, document.locale, event)
        Success.new(response_hash)
      end

    private

      def fill_out_new_edition(edition)
        create_supporting_objects(edition)
        ensure_link_set_exists(edition)

        update_last_edited_at_if_needed(edition, payload[:last_edited_at])

        if previously_published_item != ITEM_NOT_FOUND
          set_first_published_at(edition, previously_published_item)

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
          AccessLimit.create!(edition: edition, users: users)
        end
      end

      def update_existing_edition(edition)
        version = check_version_and_raise_if_conflicting(edition, payload[:previous_version])

        if content_with_base_path?
          clear_draft_items_of_same_locale_and_base_path

          previous_base_path = edition.base_path
          previous_routes = edition.routes
        end

        update_edition(edition)
        update_last_edited_at_if_needed(edition, payload[:last_edited_at])

        increment_lock_version(version)

        if path_has_changed?(previous_base_path)
          create_redirect(
            from_path: previous_base_path,
            to_path: base_path,
            routes: previous_routes,
          )
        end

        if payload[:access_limited] && (users = payload[:access_limited][:users])
          create_or_update_access_limit(edition, users: users)
        else
          AccessLimit.find_by(edition: edition).try(:destroy)
        end
      end

      def create_or_update_access_limit(edition, users:)
        if (access_limit = AccessLimit.find_by(edition: edition))
          access_limit.update_attributes!(users: users)
        else
          AccessLimit.create!(edition: edition, users: users)
        end
      end

      def clear_draft_items_of_same_locale_and_base_path
        SubstitutionHelper.clear!(
          new_item_document_type: document_type,
          new_item_content_id: document.content_id,
          state: "draft",
          locale: document.locale,
          base_path: base_path,
          downstream: downstream,
          callbacks: callbacks,
          nested: true,
        )
      end

      def edition_attributes_from_payload
        payload.slice(*Edition::TOP_LEVEL_FIELDS)
      end

      def create_edition
        attributes = edition_attributes_from_payload.merge(
          locale: document.locale,
          state: "draft",
          content_store: "draft",
          user_facing_version: user_facing_version_number_for_new_draft,
        )
        document.editions.create!(attributes)
      end

      def create_supporting_objects(edition)
        LockVersion.create!(target: edition, number: lock_version_number_for_new_draft)
      end

      def ensure_link_set_exists(edition)
        existing_link_set = LinkSet.find_by(content_id: edition.content_id)
        return if existing_link_set

        link_set = LinkSet.create!(content_id: edition.content_id)
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

      def document
        @document ||= Document.find_or_create_locked(
          content_id: payload.fetch(:content_id),
          locale: payload.fetch(:locale, Edition::DEFAULT_LOCALE),
        )
      end

      def previously_published_item
        @previously_published_item ||=
          Edition.find_by(
            document: document,
            state: %w(published unpublished),
          ) || ITEM_NOT_FOUND
      end

      def set_first_published_at(edition, previously_published_item)
        if edition.first_published_at.nil?
          edition.update_attributes(
            first_published_at: previously_published_item.first_published_at,
          )
        end
      end

      def path_has_changed?(previous_base_path)
        return false unless content_with_base_path?
        previous_base_path != base_path
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
        !Edition::EMPTY_BASE_PATH_FORMATS.include?(payload[:schema_name])
      end

      def publishing_app
        payload[:publishing_app]
      end

      def update_edition(edition)
        edition.assign_attributes_with_defaults(
          edition_attributes_from_payload.merge(
            state: "draft",
            content_store: "draft",
            user_facing_version: edition.user_facing_version,
          )
        )

        # FIXME replace this when 'content_id' and 'locale' fields are removed
        # from Edition model
        # update these fields to also update the underlying document
        edition.content_id = document.content_id
        edition.locale = document.locale

        edition.save!
      end

      def update_last_edited_at_if_needed(edition, last_edited_at = nil)
        if last_edited_at.nil? && %w(major minor).include?(payload[:update_type])
          last_edited_at = Time.zone.now
        end

        edition.update_attributes(last_edited_at: last_edited_at) if last_edited_at
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
