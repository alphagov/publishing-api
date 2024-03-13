module Sources
  class EditionLinksFromSource < GraphQL::Dataloader::Source
    def initialize(link_types)
      @link_types = link_types
    end

    # TODO untested
    def fetch(content_ids)
      query = Link
                .left_joins(edition: :document)
                .includes(edition: :document)
                .where(
                  documents: { content_id: content_ids, locale: "en" },
                )

      if @link_types.present?
        query = query.where(link_type: @link_types)
      end

      links = query
        .order(link_type: :asc, position: :asc)
        .group_by { |link| link.edition.content_id }

      content_ids.map do |content_id|
        links.fetch(content_id, []).sort_by { |link| [link.link_type, link.position] }
      end
    end
  end
end
