module Presenters
  module Queries
    class ContentItemPresenter
      # Recommend against using this method on large numbers of content items.
      # Instead, perform bulk requests for the required data and use the initializer below.
      def self.present(content_item)
        draft = ContentItemFilter.similar_to(content_item, state: "draft").first
        live = ContentItemFilter.similar_to(content_item, state: "published").first

        unless draft || live
          raise ArgumentError.new("`content_item` must be either 'draft' or 'published'")
        end

        draft_version = Version.find_by(target: draft)
        live_version = Version.find_by(target: live)

        self.new(
          draft: draft,
          live: live,
          draft_number: (draft_version.number if draft_version),
          live_number: (live_version.number if live_version),
        ).present
      end

      def initialize(draft:, live:, draft_number:, live_number:)
        self.live = live
        self.draft_number = draft_number
        self.live_number = live_number
        self.most_recent_content_item = draft || live
      end

      def present
        most_recent_content_item
          .as_json
          .symbolize_keys
          .merge(
            publication_state: publication_state,
            version: version.number,
            locale: translation.locale,
            base_path: location.base_path
          ).tap do |h|
            h[:live_version] = live_number if live_number
          end
      end

    private

      attr_accessor :most_recent_content_item, :live, :draft_number, :live_number

      def publication_state
        if draft_number && live_number && (draft_number > live_number)
          "redrafted"
        elsif live.present?
          "live"
        else
          "draft"
        end
      end

      def version
        @version ||= Version.find_by!(target: most_recent_content_item)
      end

      def translation
        @translation ||= Translation.find_by!(content_item: most_recent_content_item)
      end

      def location
        @location ||= Location.find_by!(content_item: most_recent_content_item)
      end
    end
  end
end
