module Commands
  module V2
    class CreateDraftContentItem
      def initialize(put_content, payload, previously_published_item)
        @put_content = put_content
        @payload = payload
        @previously_published_item = previously_published_item
      end

      def call
        content_item.tap do
          fill_out_new_content_item
        end
      end

    private

      attr_reader :payload, :put_content, :previously_published_item

      def content_item
        @content_item ||= create_content_item
      end

      def create_content_item
        attributes = content_item_attributes_from_payload.merge(
          locale: locale,
          state: "draft",
          content_store: "draft",
          user_facing_version: user_facing_version_number_for_new_draft,
        )
        ContentItem.create!(attributes)
      end

      def lock_version_number_for_new_draft
        previously_published_item.lock_version_number
      end

      def user_facing_version_number_for_new_draft
        previously_published_item.user_facing_version
      end

      def locale
        payload.fetch(:locale, ContentItem::DEFAULT_LOCALE)
      end

      def fill_out_new_content_item
        LockVersion.create!(target: content_item, number: lock_version_number_for_new_draft)
        ensure_link_set_exists

        set_first_published_at
      end

      def ensure_link_set_exists
        link_set = LinkSet.find_or_create_by!(content_id: content_item.content_id)
        LockVersion.find_or_create_by!(target: link_set, number: 1)
      end

      def set_first_published_at
        return unless previously_published_item.set_first_published_at?
        return if content_item.first_published_at
        content_item.update_attributes(
          first_published_at: previously_published_item.first_published_at,
        )
      end

      def content_item_attributes_from_payload
        payload.slice(*ContentItem::TOP_LEVEL_FIELDS)
      end
    end
  end
end
