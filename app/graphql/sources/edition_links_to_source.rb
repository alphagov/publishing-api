module Sources
  class EditionLinksToSource < GraphQL::Dataloader::Source
    def initialize(link_types)
      @link_types = link_types
    end

    # TODO untested
    # TODO is it a problem that we're only returning the content_ids here, not the edition ids?
    #     Maybe we should have a separate "EditionLinkType" that handles these?
    def fetch(content_ids)
      query = Link
                .left_joins(edition: :document)
                .where(
                  target_content_id: content_ids,
                  documents: { locale: "en" },
                )

      if @link_types.present?
        query = query.where(link_type: @link_types)
      end

      links = query
        .order(link_type: :asc, position: :asc)
        .group_by { |link| link.target_content_id }

      content_ids.map do |content_id|
        links.fetch(content_id, []).sort_by { |link| [link.link_type, link.position] }
      end
    end
  end
end
