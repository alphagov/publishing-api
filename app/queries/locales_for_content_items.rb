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

      scope = content_items_table
        .project(
          content_items_table[:content_id],
          content_items_table[:locale]
        )
        .distinct
        .where(content_items_table[:content_id].in(content_ids))
        .where(content_items_table[:state].in(states))
        .order(content_items_table[:content_id].asc, content_items_table[:locale].asc)

      unless include_substitutes
        unpublishings_table = Unpublishing.arel_table

        scope = scope.outer_join(unpublishings_table).on(
          content_items_table[:id].eq(unpublishings_table[:content_item_id])
            .and(content_items_table[:state].eq("unpublished"))
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
