module Queries
  module CheckForContentItemPreventingDraftFromBeingPublished
    extend ArelHelpers

    # Checks for any content item which would prevent a content item with the
    # specified content_id and base_path from being published (from the draft
    # state).
    def self.call(content_id, base_path, document_type)
      return unless base_path

      if SubstitutionHelper::SUBSTITUTABLE_DOCUMENT_TYPES.include?(document_type)
        return # The SubstitionHelper will unpublish any item that is in the way
      end

      content_items_table = ContentItem.arel_table
      unpublishings_table = Unpublishing.arel_table

      scope = content_items_table
        .project(
          content_items_table[:id]
        )
        .outer_join(unpublishings_table).on( # LEFT OUTER JOIN
          content_items_table[:id].eq(unpublishings_table[:content_item_id])
        )
        .where(content_items_table[:content_id].not_eq(content_id))
        .where(content_items_table[:state].in(%w(published unpublished)))
        .where(content_items_table[:document_type].not_in(
                 SubstitutionHelper::SUBSTITUTABLE_DOCUMENT_TYPES
        ))
        .where(content_items_table[:base_path].eq(base_path))
        .where(
          unpublishings_table[:type].not_eq("substitute")
          .or(unpublishings_table[:type].eq(nil))
        )

      rows = get_rows(scope)

      if rows.length > 1
        raise "Multiple rows returned in CheckForContentItemPreventingDraftFromBeingPublished"
      end

      rows.first["id"].to_i if rows.first
    end
  end
end
