module Commands
  module V2
    class Publish < BaseCommand
      def call
        unless (content_item = find_draft_content_item)
          message = "Item with content_id #{content_id} and locale #{locale} does not exist"
          raise CommandError.new(code: 404, message: message)
        end

        translation = Translation.find_by!(content_item: content_item)
        location = Location.find_by!(content_item: content_item)
        update_type = payload[:update_type] || content_item.update_type

        check_version_and_raise_if_conflicting(content_item, previous_version_number)

        previously_published_item = ContentItemFilter.similar_to(content_item, state: "published", base_path: nil).first
        previous_location = Location.find_by(content_item: previously_published_item)

        State.supersede(previously_published_item) if previously_published_item

        clear_published_items_of_same_locale_and_base_path(content_item, translation, location)

        set_public_updated_at(content_item, previously_published_item, update_type)
        State.publish(content_item)

        AccessLimit.find_by(content_item: content_item).try(:destroy)

        publish_redirect_if_content_item_has_moved(location, previous_location, translation)

        send_downstream(content_item, location, update_type) if downstream

        Success.new(content_id: content_id)
      end

    private
      def content_id
        payload[:content_id]
      end

      def locale
        payload.fetch(:locale, ContentItem::DEFAULT_LOCALE)
      end

      def previous_version_number
        payload[:previous_version].to_i if payload[:previous_version]
      end

      def find_draft_content_item
        filter = ContentItemFilter.new(scope: ContentItem.where(content_id: content_id))
        filter.filter(locale: locale, state: "draft").first
      end

      def clear_published_items_of_same_locale_and_base_path(content_item, translation, location)
        SubstitutionHelper.clear!(
          new_item_format: content_item.format,
          new_item_content_id: content_item.content_id,
          state: "published", locale: translation.locale, base_path: location.base_path
        )
      end

      def set_public_updated_at(content_item, previously_published_item, update_type)
        return if content_item.public_updated_at.present?

        if update_type == "major"
          content_item.update_attributes!(public_updated_at: Time.zone.now)
        elsif update_type == "minor"
          content_item.update_attributes!(public_updated_at: previously_published_item.public_updated_at)
        end
      end

      def publish_redirect_if_content_item_has_moved(new_location, previous_location, translation)
        return unless previous_location
        return if previous_location.base_path == new_location.base_path

        draft_redirect = ContentItemFilter
          .filter(state: "draft", locale: translation.locale, base_path: previous_location.base_path)
          .where(format: "redirect")
          .first

        self.class.call(
          {
            content_id: draft_redirect.content_id,
            locale: translation.locale,
            update_type: "major",
          },
          downstream: downstream,
        )
      end

      def send_downstream(content_item, location, update_type)
        return unless downstream

        ContentStoreWorker.perform_async(
          content_store: Adapters::ContentStore,
          content_item_id: content_item.id,
        )

        if update_type
          queue_payload = Presenters::MessageQueuePresenter.present(content_item, update_type: update_type)
          PublishingAPI.service(:queue_publisher).send_message(queue_payload)
        else
          raise CommandError.new(
            code: 422,
            message: "update_type is required",
            error_details: {
              error: {
                code: 422,
                message: "update_type is required",
                fields: {
                  update_type: ["is required"],
                }
              }
            }
          )
        end
      end
    end
  end
end
