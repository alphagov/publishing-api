module Sources
  class LinkedEditionsSource < GraphQL::Dataloader::Source

    def initialize(link_types)
      @link_types = link_types
    end

    # TODO - this needs to be a list of tuples of edition id and content id if we're going to do edition links as well.
    #        Or alternatively we could have two sources - one for edition links and one for link set links 🤔
    def fetch(content_ids)
      query = Edition
        .joins(document: { links: :link_set })
        .includes(document: { links: :link_set })
        .where(state: "published")
        .where(document: { locale: "en" })
        .where(document: { links: { link_sets: { content_id: content_ids } } })

      query = query.where(document: { links: { link_type: @link_types } }) if @link_types.present?

      editions_by_content_id = query.group_by { |e| e.document.links.link_sets.content_id }

      content_ids.map do |content_id|
        editions_by_content_id.fetch(content_id, []).sort_by(&:user_facing_version).last
      end
    end

  end
end
