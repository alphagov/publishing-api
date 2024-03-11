module Sources
  class LinkSetLinksToSource < GraphQL::Dataloader::Source
    def initialize(link_types)
      @link_types = link_types
    end

    def fetch(target_content_ids)
      query = Link
                .joins(:link_set)
                .where(target_content_id: target_content_ids)

      if @link_types.present?
        query = query.where(link_type: @link_types)
      end

      links = query
                .order(link_type: :asc, position: :asc)
                .includes(:link_set)
                .group_by { |link| link.target_content_id }

      target_content_ids.map do |content_id|
        links.fetch(content_id, []).sort_by { |link| [link.link_type, link.position] }
      end
    end
  end
end
