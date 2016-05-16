module Queries
  class GetExpandedLinks
    def self.call(content_id)
      link_set = LinkSet.find_by(content_id: content_id)

      expanded_link_set = Presenters::Queries::ExpandedLinkSet.new(
        link_set: link_set,
        fallback_order: [:draft, :published]
      )

      {
        expanded_links: expanded_link_set.links,
      }
    end
  end
end
