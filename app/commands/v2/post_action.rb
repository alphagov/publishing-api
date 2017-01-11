module Commands
  module V2
    class PostAction < BaseCommand
      def call
        check_version_and_raise_if_conflicting(document, previous_version_number)

        Action.create!(
          content_id: document.content_id,
          locale: document.locale,
          action: action_type,
          content_item: content_item,
          user_uid: event.user_uid,
          event: event,
        )

        Success.new(
          { content_id: document.content_id, locale: document.locale, action: action_type },
          code: 201,
        )
      end

    private

      def document
        @document ||= Document.find_or_create_locked(
          content_id: payload.fetch(:content_id),
          locale: payload.fetch(:locale, ContentItem::DEFAULT_LOCALE),
        )
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
        content_item = draft? ? document.draft : document.live

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
