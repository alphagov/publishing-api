module Sources
  class EditionSource < GraphQL::Dataloader::Source
    def fetch(content_ids)
      editions = Edition
        .with_document
        .with_unpublishing
        .where(documents: { content_id: content_ids, locale: "en" })
        .where(content_store: :live, state: :published)
        .where("unpublishings.type IS NULL OR unpublishings.type != 'substitute'")
        .includes(:document)
        .group_by { |edition| edition.content_id }

      content_ids.map do |content_id|
        editions.fetch(content_id, []).sort_by(&:user_facing_version).last
      end
    end
  end
end