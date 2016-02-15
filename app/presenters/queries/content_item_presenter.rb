module Presenters
  module Queries
    class ContentItemPresenter
      def self.present(content_item)
        translation = Translation.find_by!(content_item: content_item)

        content_items = ContentItem.where(content_id: content_item.content_id)
        content_items = Translation.filter(content_items, locale: translation.locale)
        content_items = ContentItem.where(id: content_items.pluck(:id))

        present_many(content_items).first
      end

      def self.present_many(content_item_scope)
        new(content_item_scope).present
      end

      def initialize(content_item_scope)
        self.content_item_scope = content_item_scope
      end

      def present
        scope = content_item_scope
        scope = join_supporting_objects(scope)
        scope = select_fields(scope)

        items = scope.as_json.map(&:symbolize_keys)
        groups = items.group_by { |i| i.fetch(:content_id) }

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

          most_recent_item
        end.compact
      end

    private

      attr_accessor :content_item_scope

      def join_supporting_objects(scope)
        %w(states translations locations user_facing_versions).each do |table|
          scope = scope.joins(
            "inner join #{table} on #{table}.content_item_id = content_items.id"
          )
        end

        scope = scope.joins(
          "inner join lock_versions on
            lock_versions.target_id = content_items.id and
            lock_versions.target_type = 'ContentItem'"
        )

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
