module Queries
  module LocalesForContentItem
    extend ArelHelpers

    def self.call(
      content_id,
      states = %w[draft published unpublished],
      include_substitutes = false
    )
      content_items_table = ContentItem.arel_table
      translations_table = Translation.arel_table
      states_table = State.arel_table

      scope = translations_table
        .project(translations_table[:locale]).distinct
        .join(content_items_table).on(
          content_items_table[:id].eq(translations_table[:content_item_id])
        )
        .join(states_table).on(
          content_items_table[:id].eq(states_table[:content_item_id])
        )
        .where(content_items_table[:content_id].eq(content_id))
        .where(states_table[:name].in(states))

      unless include_substitutes
        unpublishings_table = Unpublishing.arel_table

        scope = scope.outer_join(unpublishings_table).on(
          content_items_table[:id].eq(unpublishings_table[:content_item_id])
            .and(states_table[:name].eq("unpublished"))
          )
          .where(
            unpublishings_table[:type].eq(nil).or(
              unpublishings_table[:type].not_eq("substitute")
            )
          )
      end

      get_rows(scope).map { |row| row["locale"] }
    end
  end
end
