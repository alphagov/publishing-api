module Queries
  class GetExpandedLinks
    def self.call(content_id, locale)
      if (link_set = LinkSet.find_by(content_id: content_id))
        expanded_link_set(link_set, locale)
      elsif Document.where(content_id: content_id).exists?
        empty_expanded_link_set(content_id)
      else
        error_details = {
          error: {
            code: 404,
            message: "Could not find link set with content_id: #{content_id}"
          }
        }

        raise CommandError.new(code: 404, error_details: error_details)
      end
    end

    def self.expanded_link_set(link_set, locale)
      expanded_link_set = Presenters::Queries::ExpandedLinkSet.new(
        content_id: link_set.content_id,
        draft: true,
        locale: locale,
      )

      {
        content_id: link_set.content_id,
        expanded_links: expanded_link_set.links,
        version: link_set.stale_lock_version,
      }
    end

    def self.empty_expanded_link_set(content_id)
      {
        content_id: content_id,
        expanded_links: {},
        version: 0
      }
    end
  end
end
