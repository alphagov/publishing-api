module Queries
  class GetExpandedLinks
    def self.call(content_id)
      link_set = LinkSet.find_by(content_id: content_id)
      lock_version = LockVersion.find_by(target: link_set)
      expanded_link_set = Presenters::Queries::ExpandedLinkSet.new(
        link_set: link_set,
        fallback_order: [:draft, :published]
      )

      {
        content_id: content_id,
        expanded_links: expanded_link_set.links,
        version: lock_version ? lock_version.number : 0
      }
    end
  end
end
