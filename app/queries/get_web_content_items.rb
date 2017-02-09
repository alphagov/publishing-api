module Queries
  class GetWebContentItems
    extend ArelHelpers

    def self.for_content_store(content_id, locale, include_draft = false)
      allowed_states = [:published, :unpublished]
      allowed_states << :draft if include_draft

      scope = Edition.with_document
      scope = Unpublishing.join_editions(scope)

      scope
        .where(documents: { content_id: content_id, locale: locale })
        .where(state: allowed_states)
        .where("unpublishings.type IS NULL OR unpublishings.type != 'substitute'")
        .order(user_facing_version: :desc)
        .first
    end
  end
end
