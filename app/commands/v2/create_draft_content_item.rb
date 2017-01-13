module Commands
  module V2
    class CreateDraftContentItem
      def initialize(put_content, payload)
        @put_content = put_content
        @payload = payload
      end

      def call
        content_item.tap do
          fill_out_new_content_item
        end
      end

    private

      NoPreviousPublishedItem = Class.new do
        def user_facing_version
          0
        end
      end

      attr_reader :payload, :put_content

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

      def previously_published_item
        @previously_published_item ||=
          ContentItem.find_by(
            content_id: payload.fetch(:content_id),
            state: %w(published unpublished),
            locale: locale,
        ) || NoPreviousPublishedItem.new
      end

      def lock_version_number_for_new_draft
        return 1 if previously_published_item.class == NoPreviousPublishedItem
        lock_version = LockVersion.find_by!(target: previously_published_item)
        lock_version.number + 1
      end

      def user_facing_version_number_for_new_draft
        previously_published_item.user_facing_version + 1
      end

      def locale
        payload.fetch(:locale, ContentItem::DEFAULT_LOCALE)
      end

      def fill_out_new_content_item
        LockVersion.create!(target: content_item, number: lock_version_number_for_new_draft)
        ensure_link_set_exists

        previously_published_item_actions
      end

      def ensure_link_set_exists
        link_set = LinkSet.find_or_create_by!(content_id: content_item.content_id)
        LockVersion.find_or_create_by!(target: link_set, number: 1)
      end

      def previously_published_item_actions
        return if previously_published_item.class == NoPreviousPublishedItem

        set_first_published_at
        previous_base_path = previously_published_item.base_path

        if path_has_changed?(previous_base_path)
          create_redirect(
            from_path: previous_base_path,
            to_path: payload[:base_path],
            routes: previously_published_item.routes,
          )
        end
      end

      def set_first_published_at
        return if content_item.first_published_at
        content_item.update_attributes(
          first_published_at: previously_published_item.first_published_at,
        )
      end

      def create_redirect(from_path:, to_path:, routes:)
        RedirectHelper.create_redirect(
          publishing_app: payload[:publishing_app],
          old_base_path: from_path,
          new_base_path: to_path,
          routes: routes,
          callbacks: put_content.callbacks,
        )
      end

      def path_has_changed?(previous_base_path)
        return false unless put_content.content_with_base_path?
        previous_base_path != payload[:base_path]
      end

      def content_item_attributes_from_payload
        payload.slice(*ContentItem::TOP_LEVEL_FIELDS)
      end
    end
  end
end
