module Queries
  module CheckForContentItemPreventingDraftFromBeingPublished
    extend ArelHelpers

    # Checks for any content item which would prevent a content item with the
    # specified content_id and base_path from being published (from the draft
    # state).
    def self.call(content_id, base_path, document_type)
      if SubstitutionHelper::SUBSTITUTABLE_DOCUMENT_TYPES.include?(document_type)
        return # The SubstitionHelper will unpublish any item that is in the way
      end

      content_items_table = table(:content_items)
      states_table = table(:states)
      locations_table = table(:locations)
      unpublishings_table = table(:unpublishings)

      scope = content_items_table
        .project(
          content_items_table[:id]
        )
        .join(states_table).on(
          content_items_table[:id].eq(states_table[:content_item_id])
        )
        .join(locations_table).on(
          content_items_table[:id].eq(locations_table[:content_item_id])
        )
        .outer_join(unpublishings_table).on( # LEFT OUTER JOIN
          content_items_table[:id].eq(unpublishings_table[:content_item_id])
        )
        .where(content_items_table[:content_id].not_eq(content_id))
        .where(states_table[:name].in(%w(published unpublished)))
        .where(content_items_table[:document_type].not_in(
                 SubstitutionHelper::SUBSTITUTABLE_DOCUMENT_TYPES
        ))
        .where(locations_table[:base_path].eq(base_path))
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
