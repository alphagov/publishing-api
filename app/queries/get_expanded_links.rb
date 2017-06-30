module Queries
  class GetExpandedLinks
    def self.call(content_id, locale, with_drafts: true)
      if (link_set = LinkSet.find_by(content_id: content_id))
        expanded_link_set(link_set, locale, with_drafts: with_drafts)
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

    def self.expanded_link_set(link_set, locale, with_drafts:)
      expanded_link_set = Presenters::Queries::ExpandedLinkSet.by_content_id(
        link_set.content_id,
        locale: locale,
        with_drafts: with_drafts,
      )

      cache_key = ["expanded-link-set", link_set.content_id, locale, with_drafts]
      expanded_links = Rails.cache.fetch(cache_key) do
        expanded_link_set.links
      end

      {
        content_id: link_set.content_id,
        expanded_links: expanded_links,
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
