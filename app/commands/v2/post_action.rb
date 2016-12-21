module Commands
  module V2
    class PostAction < BaseCommand
      def call
        check_version_and_raise_if_conflicting(content_item, previous_version_number)

        Action.create!(
          content_id: content_id,
          locale: locale,
          action: action_type,
          content_item: content_item,
          user_uid: event.user_uid,
          event: event,
        )

        Success.new(
          { content_id: content_id, locale: locale, action: action_type },
          code: 201,
        )
      end

    private

      def content_id
        payload.fetch(:content_id)
      end

      def locale
        payload.fetch(:locale, ContentItem::DEFAULT_LOCALE)
      end

      def draft?
        payload[:draft].nil? ? true : payload[:draft]
      end

      def content_item
        @content_item ||= find_content_item
      end

      def action_type
        payload[:action]
      end

      def find_content_item
        content_item = ContentItem.joins(:document).find_by(
          'documents.content_id': content_id,
          'documents.locale': locale,
          state: draft? ? %w(draft) : %w(published unpublished),
        )

        unless content_item
          message = "Could not find a content item to associate this action with"
          raise_command_error(404, message, fields: {})
        end
        content_item
      end

      def previous_version_number
        payload[:previous_version].to_i if payload[:previous_version]
      end
    end
  end
end
