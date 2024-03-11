module Queries
  class GetEditionForBasePath
    def self.call(base_path, locale, include_draft: false)
      relation(base_path, locale, include_draft:).first
    end

    def self.relation(base_path, locale, include_draft: false)
      allowed_content_stores = [:live]
      allowed_content_stores << :draft if include_draft

      Edition
        .with_document
        .with_unpublishing
        .where(base_path:)
        .where(documents: { locale: })
        .where(content_store: allowed_content_stores)
        .where("unpublishings.type IS NULL OR unpublishings.type != 'substitute'")
        .order(user_facing_version: :desc)
    end
  end
end
