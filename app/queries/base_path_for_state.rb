module Queries
  module BasePathForState
    extend ArelHelpers

    def self.conflict(content_item_id, state, base_path)
      return if state == "superseded"
      return if state == "unpublished" && Unpublishing.is_substitute?(content_item_id)

      content_items_table = ContentItem.arel_table
      unpublishings_table = Unpublishing.arel_table

      allowed_states = state == "draft" ? %w(draft) : %w(published unpublished)

      scope = content_items_table
        .project(
          content_items_table[:id],
          content_items_table[:content_id],
          content_items_table[:locale]
        )
        .where(content_items_table[:id].not_eq(content_item_id))
        .where(content_items_table[:state].in(allowed_states))
        .where(content_items_table[:base_path].eq(base_path))

      if %w(published unpublished).include?(state)
        unpublished_state = content_items_table[:state].eq("unpublished")
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
