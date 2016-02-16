module Presenters
  module Queries
    class ContentItemPresenter
      def self.present(content_item)
        translation = Translation.find_by!(content_item: content_item)

        content_items = ContentItem.where(content_id: content_item.content_id)
        content_items = Translation.filter(content_items, locale: translation.locale)

        present_many(content_items).first
      end

      def self.present_many(content_item_scope)
        new(content_item_scope).present
      end

      def initialize(content_item_scope)
        self.content_item_scope = content_item_scope
      end

      def present
        scope = join_supporting_objects(content_item_scope)
        scope = select_fields(scope)

        items = scope.as_json.map(&:symbolize_keys)
        groups = items.group_by { |i| [i.fetch(:content_id), i.fetch(:locale)] }

        groups.map do |_, items|
          draft = detect_draft(items)
          live = detect_live(items)

          most_recent_item = draft || live
          next unless most_recent_item

          most_recent_item.merge!(
            publication_state: publication_state(draft, live)
          )

          most_recent_item.merge!(
            live_version: live.fetch(:lock_version)
          ) if live

          most_recent_item = most_recent_item.except(:id, :state_name)

          most_recent_item
        end.compact
      end

    private

      attr_accessor :content_item_scope

      def remove_existing_joins(scope)
        scope = ContentItem.where(id: scope.pluck(:id))
      end

      def join_supporting_objects(scope)
        scope = remove_existing_joins(scope)
        scope = State.join_content_items(scope)
        scope = Translation.join_content_items(scope)
        scope = Location.join_content_items(scope)
        scope = UserFacingVersion.join_content_items(scope)
        scope = LockVersion.join_content_items(scope)

        scope
      end

      def select_fields(scope)
        scope.select(
          *ContentItem::TOP_LEVEL_FIELDS,
          "states.name as state_name",
          "lock_versions.number as lock_version",
          "translations.locale",
          "locations.base_path",
        )
      end

      def publication_state(draft, live)
        draft_lock_version = draft.fetch(:lock_version) if draft
        live_lock_version = live.fetch(:lock_version) if live

        if draft_lock_version && live_lock_version && (draft_lock_version > live_lock_version)
          "redrafted"
        elsif live
          "live"
        elsif draft
          "draft"
        else
          raise "Something unexpected happened"
        end
      end

      def detect_draft(items)
        draft = items.detect { |i| i.fetch(:state_name) == "draft" }
      end

      def detect_live(items)
        live = items.detect { |i| i.fetch(:state_name) == "published" }
      end
    end
  end
end
