module Queries
  class GetExpandedLinks
    def self.call(content_id, locale)
      link_set = find_link_set(content_id)
      expanded_link_set = Presenters::Queries::ExpandedLinkSet.new(
        content_id: content_id,
        state_fallback_order: [:draft, :published],
        locale_fallback_order: [locale, Edition::DEFAULT_LOCALE].compact
      )

      {
        content_id: content_id,
        expanded_links: expanded_link_set.links,
        version: link_set.stale_lock_version,
      }
    end

    def self.find_link_set(content_id)
      LinkSet.find_by!(content_id: content_id)
    rescue ActiveRecord::RecordNotFound
      error_details = {
        error: {
          code: 404,
          message: "Could not find link set with content_id: #{content_id}"
        }
      }

      raise CommandError.new(code: 404, error_details: error_details)
    end
  end
end
