module Queries
  module LocalesForContentItems
    extend ArelHelpers

    # returns an array of form:
    # [
    #   [content_id, locale],
    #   [content_id, locale],
    # ]
    def self.call(
      content_ids,
      states = %w[draft published unpublished],
      include_substitutes = false
    )
      content_items_table = ContentItem.arel_table
      translations_table = Translation.arel_table
      states_table = State.arel_table

      scope = translations_table
        .project(
          content_items_table[:content_id],
          translations_table[:locale]
        )
        .distinct
        .join(content_items_table).on(
          content_items_table[:id].eq(translations_table[:content_item_id])
        )
        .join(states_table).on(
          content_items_table[:id].eq(states_table[:content_item_id])
        )
        .where(content_items_table[:content_id].in(content_ids))
        .where(states_table[:name].in(states))
        .order(content_items_table[:content_id].asc, translations_table[:locale].asc)

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

      get_rows(scope).map { |row| [row["content_id"], row["locale"]] }
    end
  end
end
