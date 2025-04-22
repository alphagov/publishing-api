module Queries
  module RecursiveLinkExpansion
    class ReverseEditionLinks
      def call
        # TODO: - parameterize locale / state
        Edition
          .from("lookahead")
          .joins("INNER JOIN links ON (links.target_content_id = lookahead.content_id AND links.link_type = lookahead.type AND lookahead.reverse = true)")
          .joins("INNER JOIN editions ON (editions.id = links.edition_id AND editions.state='published')")
          .joins("INNER JOIN documents ON (documents.id = editions.document_id AND documents.locale='en')")
          .select(
            "'1 forward edition link' as type",
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
