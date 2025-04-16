module Queries
  module RecursiveLinkExpansion
    ##
    # Expects to be called with a CTE called "linked_editions" already defined.
    # Defines a "lookahead" from a content id or an edition id and a link type.
    #
    # This allows the various types of link query (forward / reverse link set / edition links) to
    # follow the link type from the edition / content id to the next edition / content_id.
    #
    # links is required in the constructor because we need to provide the maximum number of links that
    # this CTE could return, as otherwise the postgresql planner will assume jsonb_to_recordset() will return 100 rows
    # which pushes it towards inefficient plans.
    class Lookahead
      def initialize(links)
        @links = links.map(&:deep_symbolize_keys)
      end

      def call
        Arel.sql(<<~SQL
            SELECT content_id, edition_id, path, lookahead.type, lookahead.reverse, lookahead.links
            FROM linked_editions
            CROSS JOIN LATERAL (
              SELECT * from jsonb_to_recordset(linked_editions.links) AS lookahead(type varchar, reverse boolean, links jsonb)
              LIMIT #{max_links_count(@links)}
            ) AS lookahead
          SQL
        )
      end

    private

      def max_links_count(links)
        case links
        in { links: Array => ls } then max_links_count(ls)
        in Hash | [] then 0
        in Array then [links.length, links.map { max_links_count(_1) }.max].max
        end
      end
    end
  end
end
