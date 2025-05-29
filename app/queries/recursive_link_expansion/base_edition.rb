module Queries
  module RecursiveLinkExpansion
    ##
    # Selects the columns required for recursive link expansion from the base edition (the root edition in the tree)
    class BaseEdition
      def initialize(edition_with_document, links = [])
        @edition = edition_with_document
        @links = links
      end

      def call
        Edition.with_document.where(id: @edition.id).select(
          "'0 base' as type",
          "'{}'::text[] as path",
          "documents.content_id",
          "documents.locale",
          "editions.id as edition_id",
          "0 as position",
          "editions.state",
          ActiveRecord::Base.send(:sanitize_sql_array, ["?::jsonb as links", @links.to_json]),
        )
      end
    end
  end
end
