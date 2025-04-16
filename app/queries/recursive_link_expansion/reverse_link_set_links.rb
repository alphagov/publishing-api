module Queries
  module RecursiveLinkExpansion
    class ReverseLinkSetLinks
      def call
        # TODO - parameterize locale / state
        Edition
          .from("lookahead")
          .joins("INNER JOIN links ON links.target_content_id = lookahead.content_id and links.link_type = lookahead.type and lookahead.reverse = true")
          .joins("INNER JOIN documents ON documents.content_id = links.link_set_content_id and documents.locale IN ('en')")
          .joins("INNER JOIN editions ON editions.document_id = documents.id AND editions.state IN ('published')")
          .select(
            "'4 reverse link set link' as type",
            "path || lookahead.content_id::text || lookahead.type as path",
            "documents.content_id",
            "documents.locale",
            "editions.id as edition_id",
            "links.position as position",
            "editions.state as state",
            "lookahead.links",
            )
      end
    end
  end
end