module Commands
  module V2
    class PreviouslyPublishedItem
      def initialize(content_id, base_path, locale, put_content)
        @content_id = content_id
        @base_path = base_path
        @locale = locale
        @put_content = put_content
      end

      attr_reader :content_id, :base_path, :locale, :put_content

      def call
        previously_published_item ? self : NoPreviousPublishedItem.new
      end

      def previously_published_item
        @previously_published_item ||=
          ContentItem.find_by(content_id: content_id,
                              state: %w(published unpublished),
                              locale: locale)
      end

      def lock_version_number
        previously_published_item.lock_version_number + 1
      end

      def user_facing_version
        previously_published_item.user_facing_version + 1
      end

      def set_first_published_at?
        true
      end

      def first_published_at
        previously_published_item.first_published_at
      end

      def previous_base_path
        previously_published_item.base_path
      end

      def routes
        previously_published_item.routes
      end

      def path_has_changed?
        previous_base_path != base_path
      end

      class NoPreviousPublishedItem
        def lock_version_number
          1
        end

        def user_facing_version
          1
        end

        def set_first_published_at?
          false
        end

        def path_has_changed?
          false
        end

        def previous_base_path
        end

        def routes
        end
      end
    end
  end
end
