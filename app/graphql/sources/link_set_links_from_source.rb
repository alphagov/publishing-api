module Sources
  class LinkSetLinksFromSource < GraphQL::Dataloader::Source
    def initialize(link_types)
      @link_types = link_types
    end

    def fetch(content_ids)
      query = Link
        .joins(:link_set)
        .where(link_sets: {content_id: content_ids})

      if @link_types.present?
        query = query.where(link_type: @link_types)
      end

      links = query
        .order(link_type: :asc, position: :asc)
        .includes(:link_set)
        .group_by { |link| link.link_set.content_id }

      content_ids.map do |content_id|
        links.fetch(content_id, []).sort_by { |link| [link.link_type, link.position] }
      end
    end
  end
end
