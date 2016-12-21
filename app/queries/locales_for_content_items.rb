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
      documents_table = Document.arel_table
      content_items_table = ContentItem.arel_table

      scope = documents_table
        .project(
          documents_table[:content_id],
          documents_table[:locale]
        )
        .distinct
        .join(content_items_table)
          .on(content_items_table[:document_id].eq(documents_table[:id])
            .and(content_items_table[:state].in(states)))
        .where(documents_table[:content_id].in(content_ids))
        .order(documents_table[:content_id].asc, documents_table[:locale].asc)

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
