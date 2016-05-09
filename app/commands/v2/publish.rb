module Commands
  module V2
    class Publish < BaseCommand
      def call
        unless (content_item = find_draft_content_item)
          if already_published?
            message = "Cannot publish an already published content item"
            raise_command_error(400, message, fields: {})
          else
            message = "Item with content_id #{content_id} and locale #{locale} does not exist"
            raise_command_error(404, message, fields: {})
          end
        end

        translation = Translation.find_by!(content_item: content_item)
        location = Location.find_by!(content_item: content_item)
        update_type = payload[:update_type] || content_item.update_type

        if update_type.blank?
          raise_command_error(422, "update_type is required", fields: {
            update_type: ["is invalid"],
          })
        elsif !valid_update_types.include?(update_type)
          raise_command_error(422, "An update_type of '#{update_type}' is invalid", fields: {
            update_type: ["must be one of #{valid_update_types.inspect}"],
          })
        end

        check_version_and_raise_if_conflicting(content_item, previous_version_number)

        previous_item = lookup_published_item(content_item)
        previous_location = Location.find_by(content_item: previous_item)

        publish_redirect_if_content_item_has_moved(location, previous_location, translation)

        previous_item = lookup_published_item(content_item)
        State.supersede(previous_item) if previous_item

        clear_published_items_of_same_locale_and_base_path(content_item, translation, location)

        set_public_updated_at(content_item, previous_item, update_type)
        set_first_published_at(content_item)
        State.publish(content_item)

        AccessLimit.find_by(content_item: content_item).try(:destroy)

        [Success.new(content_id: content_id), send_downstream(content_item, update_type)]
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

      def valid_update_types
        %w(major minor republish links)
      end

      def find_draft_content_item
        filter = ContentItemFilter.new(scope: ContentItem.where(content_id: content_id))
        filter.filter(locale: locale, state: "draft").first
      end

      def already_published?
        filter = ContentItemFilter.new(scope: ContentItem.where(content_id: content_id))
        filter.filter(locale: locale, state: "published").first
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

      def set_first_published_at(content_item)
        return if content_item.first_published_at.present?
        content_item.update_attributes!(first_published_at: Time.zone.now)
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

      def lookup_published_item(content_item)
        ContentItemFilter.similar_to(
          content_item,
          state: "published",
          base_path: nil,
          user_version: nil,
        ).first
      end

      def send_downstream(content_item, update_type)
        queue_payload = Presenters::MessageQueuePresenter.present(
          content_item,
          fallback_order: [:published],
          update_type: update_type
        )

        PublishingAPI.service(:queue_publisher).send_message(queue_payload)

        lambda do
          PresentedContentStoreWorker.perform_async(
            content_store: Adapters::ContentStore,
            payload: { content_item: content_item.id, payload_version: event.id },
            request_uuid: GdsApi::GovukHeaders.headers[:govuk_request_id]
          )
        end
      end
    end
  end
end
