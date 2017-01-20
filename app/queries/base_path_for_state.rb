module Queries
  module BasePathForState
    extend ArelHelpers

    def self.conflict(edition_id, state, base_path)
      return if state == "superseded"
      return if state == "unpublished" && Unpublishing.is_substitute?(edition_id)

      documents_table = Document.arel_table
      editions_table = Edition.arel_table
      unpublishings_table = Unpublishing.arel_table

      allowed_states = state == "draft" ? %w(draft) : %w(published unpublished)

      scope = editions_table
        .project(
          editions_table[:id],
          documents_table[:content_id],
          documents_table[:locale],
        )
        .where(editions_table[:id].not_eq(edition_id))
        .where(editions_table[:state].in(allowed_states))
        .where(editions_table[:base_path].eq(base_path))
        .join(documents_table).on(documents_table[:id].eq(editions_table[:document_id]))

      if %w(published unpublished).include?(state)
        unpublished_state = editions_table[:state].eq("unpublished")
        editions_join = editions_table[:id].eq(unpublishings_table[:content_item_id])
        nil_unpublishing = unpublishings_table[:type].eq(nil)
        non_substitute = unpublishings_table[:type].not_eq("substitute")

        scope = scope.outer_join(unpublishings_table)
          .on(unpublished_state.and(editions_join))
          .where(nil_unpublishing.or(non_substitute))
      end

      scope = scope.order(editions_table[:created_at].desc).take(1)
      get_rows(scope).first.try(:symbolize_keys)
    end
  end
end
