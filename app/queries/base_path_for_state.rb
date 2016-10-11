module Queries
  module BasePathForState
    extend ArelHelpers

    def self.conflict(content_item_id, state, base_path)
      return if state == "superseded"
      return if state == "unpublished" && Unpublishing.is_substitute?(content_item_id)

      content_items_table = ContentItem.arel_table
      states_table = State.arel_table
      locations_table = Location.arel_table
      translations_table = Translation.arel_table
      unpublishings_table = Unpublishing.arel_table

      allowed_states = state == "draft" ? %w(draft) : %w(published unpublished)

      scope = content_items_table
        .project(
          content_items_table[:id],
          content_items_table[:content_id],
          translations_table[:locale]
        )
        .join(states_table).on(
          content_items_table[:id].eq(states_table[:content_item_id])
        )
        .join(locations_table).on(
          content_items_table[:id].eq(locations_table[:content_item_id])
        )
        .outer_join(translations_table).on(
          content_items_table[:id].eq(translations_table[:content_item_id])
        )
        .where(content_items_table[:id].not_eq(content_item_id))
        .where(states_table[:name].in(allowed_states))
        .where(locations_table[:base_path].eq(base_path))

      if %w(published unpublished).include?(state)
        unpublished_state = states_table[:name].eq("unpublished")
        content_items_join = content_items_table[:id].eq(unpublishings_table[:content_item_id])
        nil_unpublishing = unpublishings_table[:type].eq(nil)
        non_substitute = unpublishings_table[:type].not_eq("substitute")

        scope = scope.outer_join(unpublishings_table)
          .on(unpublished_state.and(content_items_join))
          .where(nil_unpublishing.or(non_substitute))
      end

      scope = scope.order(content_items_table[:created_at].desc).take(1)
      get_rows(scope).first.try(:symbolize_keys)
    end
  end
end
