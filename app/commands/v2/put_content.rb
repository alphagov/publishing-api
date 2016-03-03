module Commands
  module V2
    class PutContent < BaseCommand
      def call
        raise_if_links_is_provided

        PathReservation.reserve_base_path!(base_path, publishing_app)

        if (content_item = find_previously_drafted_content_item)
          clear_draft_items_of_same_locale_and_base_path(content_item, locale, base_path)

          location = Location.find_by!(content_item: content_item)
          translation = Translation.find_by!(content_item: content_item)

          check_version_and_raise_if_conflicting(content_item, payload[:previous_version])

          update_content_item(content_item)
          increment_lock_version(content_item)

          if path_has_changed?(location)
            from_path = location.base_path
            update_path(location, new_path: base_path)
            create_redirect(from_path: from_path, to_path: base_path, locale: translation.locale)
          end

          if payload[:access_limited] && (users = payload[:access_limited][:users])
            create_or_update_access_limit(content_item, users: users)
          else
            AccessLimit.find_by(content_item: content_item).try(:destroy)
          end
        else
          content_item = create_content_item
          clear_draft_items_of_same_locale_and_base_path(content_item, locale, base_path)

          create_supporting_objects(content_item)
          ensure_link_set_exists(content_item)

          if payload[:access_limited] && (users = payload[:access_limited][:users])
            AccessLimit.create!(content_item: content_item, users: users)
          end
        end

        send_downstream(content_item) if downstream

        response_hash = Presenters::Queries::ContentItemPresenter.present(content_item)
        Success.new(response_hash)
      end

    private

      def create_or_update_access_limit(content_item, users:)
        if (access_limit = AccessLimit.find_by(content_item: content_item))
          access_limit.update_attributes!(users: users)
        else
          AccessLimit.create!(content_item: content_item, users: users)
        end
      end

      def find_previously_drafted_content_item
        filter = ContentItemFilter.new(scope: ContentItem.where(content_id: content_id))
        filter.filter(locale: locale, state: "draft").first
      end

      def clear_draft_items_of_same_locale_and_base_path(content_item, locale, base_path)
        SubstitutionHelper.clear!(
          new_item_format: content_item.format,
          new_item_content_id: content_item.content_id,
          state: "draft",
          locale: locale,
          base_path: base_path,
        )
      end

      def content_item_attributes_from_payload
        payload.slice(*ContentItem::TOP_LEVEL_FIELDS)
      end

      def create_content_item
        ContentItem.create!(content_item_attributes_from_payload)
      end

      def create_supporting_objects(content_item)
        Location.create!(content_item: content_item, base_path: base_path)
        State.create!(content_item: content_item, name: "draft")
        Translation.create!(content_item: content_item, locale: locale)
        UserFacingVersion.create!(content_item: content_item, number: user_facing_version_number_for_new_draft)
        LockVersion.create!(target: content_item, number: lock_version_number_for_new_draft)
      end

      def ensure_link_set_exists(content_item)
        existing_link_set = LinkSet.find_by(content_id: content_item.content_id)
        return if existing_link_set

        link_set = LinkSet.create!(content_id: content_item.content_id)
        LockVersion.create!(target: link_set, number: 1)
      end

      def lock_version_number_for_new_draft
        if previously_published_item
          lock_version = LockVersion.find_by!(target: previously_published_item)
          lock_version.number + 1
        else
          1
        end
      end

      def user_facing_version_number_for_new_draft
        if previously_published_item
          user_facing_version = UserFacingVersion.find_by!(content_item: previously_published_item)
          user_facing_version.number + 1
        else
          1
        end
      end

      def previously_published_item
        @previously_published_item ||= (
          filter = ContentItemFilter.new(scope: ContentItem.where(content_id: content_id))
          filter.filter(state: "published", locale: locale).first
        )
      end

      def path_has_changed?(location)
        location.base_path != base_path
      end

      def update_path(location, new_path:)
        location.update_attributes!(base_path: new_path)
      end

      def content_id
        payload.fetch(:content_id)
      end

      def base_path
        payload.fetch(:base_path)
      end

      def locale
        payload.fetch(:locale, ContentItem::DEFAULT_LOCALE)
      end

      def publishing_app
        payload.fetch(:publishing_app)
      end

      def update_content_item(content_item)
        content_item.assign_attributes_with_defaults(content_item_attributes_from_payload)
        content_item.save!
      end

      def increment_lock_version(content_item)
        lock_version = LockVersion.find_by!(target: content_item)
        lock_version.increment
        lock_version.save!
      end

      def create_redirect(from_path:, to_path:, locale:)
        RedirectHelper.create_redirect(
          publishing_app: publishing_app,
          old_base_path: from_path,
          new_base_path: to_path,
          locale: locale,
        )
      end

      def send_downstream(content_item)
        return unless downstream

        ContentStorePayloadVersion.increment(content_item.id)
        ContentStoreWorker.perform_in(
          1.second,
          content_store: Adapters::DraftContentStore,
          content_item_id: content_item.id,
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
    end
  end
end
