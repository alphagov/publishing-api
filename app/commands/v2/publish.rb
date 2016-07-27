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
        location = Location.find_by(content_item: content_item)
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

        previous_item = lookup_previous_item(content_item)
        previous_location = Location.find_by(content_item: previous_item)

        State.supersede(previous_item) if previous_item

        unless pathless?(content_item)
          publish_redirect_if_content_item_has_moved(location, previous_location, translation)
          clear_published_items_of_same_locale_and_base_path(content_item, translation, location)
        end

        set_public_updated_at(content_item, previous_item, update_type)
        set_first_published_at(content_item)
        State.publish(content_item)
        update_linkable(content_item)

        AccessLimit.find_by(content_item: content_item).try(:destroy)

        after_transaction_commit do
          send_downstream(content_item, update_type)
        end

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

      def valid_update_types
        %w(major minor republish links)
      end

      def update_linkable(content_item)
        Linkable.where(content_item: content_item).update_all(state: "published")
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
          new_item_document_type: content_item.document_type,
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

      def pathless?(content_item)
        !Location.exists?(content_item: content_item) &&
          ContentItem::EMPTY_BASE_PATH_FORMATS.include?(content_item.schema_name || content_item.format)
      end

      def publish_redirect_if_content_item_has_moved(new_location, previous_location, translation)
        return unless previous_location
        return if previous_location.base_path == new_location.base_path

        draft_redirect = ContentItemFilter
          .filter(state: "draft", locale: translation.locale, base_path: previous_location.base_path)
          .where(schema_name: "redirect")
          .first

        self.class.call(
          {
            content_id: draft_redirect.content_id,
            locale: translation.locale,
            update_type: "major",
          },
          downstream: downstream,
          callbacks: callbacks,
          nested: true,
        ) if draft_redirect
      end

      def lookup_previous_item(content_item)
        previous_items = ContentItemFilter.similar_to(
          content_item,
          state: %w(published unpublished),
          base_path: nil,
          user_version: nil,
        ).to_a

        if previous_items.size > 1
          raise "There should only be one previous published or unpublished item"
        end

        previous_items.first
      end

      def send_downstream(content_item, update_type)
        return unless downstream

        queue = update_type == 'republish' ? DownstreamPublishWorker::LOW_QUEUE : DownstreamPublishWorker::HIGH_QUEUE

        DownstreamPublishWorker.perform_async_in_queue(
          queue,
          content_item_id: content_item.id,
          send_to_content_store: !pathless?(content_item),
          message_queue_update_type: update_type,
          payload_version: event.id,
        )
      end
    end
  end
end
