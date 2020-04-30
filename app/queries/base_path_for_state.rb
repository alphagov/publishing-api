module Queries
  module BasePathForState
    extend self

    def conflict(edition_id, state, base_path)
      return if has_no_conflicts?(state, edition_id)

      id, content_id, locale = find_conflict(
        limit_scope_to_unpublishing(
          edition_scope(edition_id, state, base_path), state
        ),
      )

      { id: id, content_id: content_id, locale: locale } if id
    end

    def find_conflict(scope)
      scope
        .order(created_at: :desc)
        .pluck("editions.id", :content_id, :locale)
        .first
    end

    def has_no_conflicts?(state, edition_id)
      return true if state == "superseded"
      return true if state == "unpublished" && Unpublishing.is_substitute?(edition_id)

      false
    end

    def edition_scope(edition_id, state, base_path)
      Edition
        .with_document
        .where.not(id: edition_id)
        .where(state: allowed_states(state))
        .where(base_path: base_path)
    end

    def allowed_states(state)
      state == "draft" ? %w[draft] : %w[published unpublished]
    end

    def limit_scope_to_unpublishing(scope, state)
      return scope unless %w[published unpublished].include?(state)

      scope
        .with_unpublishing
        .where("unpublishings.type IS NULL OR unpublishings.type != 'substitute'")
    end
  end
end
