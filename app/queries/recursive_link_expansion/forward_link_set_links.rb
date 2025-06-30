module Queries
  module RecursiveLinkExpansion
    class ForwardLinkSetLinks
      def call
        # TODO: - parameterize locale / state
        Edition
          .from("lookahead")
          .joins("INNER JOIN links ON (links.link_set_content_id = lookahead.content_id AND links.link_type = lookahead.type AND lookahead.reverse = false)")
          .joins("INNER JOIN documents ON (documents.content_id = links.target_content_id AND documents.locale='en')")
          .joins("INNER JOIN editions ON (editions.document_id = documents.id AND editions.state='published')")
          .select(
            "'2 forward link set link' as type",
            "path || lookahead.content_id::text || lookahead.type AS path",
            "documents.content_id",
            "documents.locale",
            "editions.id as edition_id",
            "links.position",
            "editions.state",
            "lookahead.links",
          )
      end
    end
  end
end
