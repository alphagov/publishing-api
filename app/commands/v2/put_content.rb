module Commands
  module V2
    class PutContent < BaseCommand
      def call
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

          supporting_objects = create_supporting_objects(content_item)
          location = supporting_objects.fetch(:location)

          if payload[:access_limited] && (users = payload[:access_limited][:users])
            AccessLimit.create!(content_item: content_item, users: users)
          end
        end

        send_downstream(content_item, location) if downstream

        response_hash = Presenters::Queries::ContentItemPresenter.present(content_item)
        Success.new(response_hash)
      end

    private

      def create_or_update_access_limit(content_item, users:)
        if access_limit = AccessLimit.find_by(content_item: content_item)
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
        {
          location: Location.create!(content_item: content_item, base_path: base_path),
          state: State.create!(content_item: content_item, name: "draft"),
          translation: Translation.create!(content_item: content_item, locale: locale),
          user_facing_version: UserFacingVersion.create!(content_item: content_item, number: 1),
          lock_version: LockVersion.create!(target: content_item, number: lock_version_number_for_new_draft),
        }
      end

      def lock_version_number_for_new_draft
        filter = ContentItemFilter.new(scope: ContentItem.where(content_id: content_id))
        previously_published_item = filter.filter(state: "published", locale: locale).first

        if previously_published_item
          lock_version = LockVersion.find_by!(target: previously_published_item)
          lock_version.number + 1
        else
          1
        end
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

      def send_downstream(content_item, location)
        return unless downstream

        content_store_payload = Presenters::ContentStorePresenter.present(content_item)
        ContentStoreWorker.perform_async(
          content_store: Adapters::DraftContentStore,
          base_path: location.base_path,
          payload: content_store_payload,
        )
      end
    end
  end
end
