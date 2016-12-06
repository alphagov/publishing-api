module Queries
  # Used to return a list of content ids that are linked to a specificied
  # content id.
  #
  # Uses expansion_rules to recursively determine content ids of items that
  # indirectly are linked to a content id.
  #
  # Designed to be used to determine which links to update as part of
  # dependency resoultion.
  class LinkedTo
    def call(content_id:, expansion_rules:)
      linked_to(content_id, expansion_rules)
    end

    def linked_to(content_id, expansion_rules)
      all_results = results(content_id, expansion_rules.recursive_link_types)
      filtered = all_results.select do |result|
        link_type_path = JSON.parse(result["link_type_path"]).reverse
        link_type_path.count == 1 || expansion_rules.valid_link_recursion?(link_type_path)
      end
      filtered.map { |result| JSON.parse(result["content_id_path"]) }.flatten.uniq
    end

    def results(content_id, recursive_link_types)
      connection = ActiveRecord::Base.connection
      if recursive_link_types.any?
        quoted_link_types = recursive_link_types.flatten.map { |s| connection.quote(s) }.join(",")
        link_type_condition = "found_links.link_type IN (#{quoted_link_types}) AND links.link_type IN (#{quoted_link_types})"
      else
        link_type_condition = "1 = 0"
      end
      connection.execute(
        <<-SQL
          WITH RECURSIVE found_links (
            content_id, link_type, link_type_path, content_id_path
          ) AS (
            -- All links which target this content item
            SELECT
              link_sets.content_id,
              links.link_type,
              ARRAY[links.link_type],
              ARRAY[link_sets.content_id]
            FROM link_sets
            INNER JOIN links
              ON link_sets.id = links.link_set_id
            WHERE links.target_content_id = #{connection.quote(content_id)}
          UNION
            -- Recursive links which target a link we have found
            -- and both previous and current link type are of a recursive type
            -- and is not one of the parents of this link (to avoid a cycle)
            SELECT
              link_sets.content_id,
              links.link_type,
              array_append(found_links.link_type_path, links.link_type),
              array_append(found_links.content_id_path, link_sets.content_id)
            FROM found_links
            JOIN links
              ON links.target_content_id = found_links.content_id
            JOIN link_sets
              ON link_sets.id = links.link_set_id
            WHERE NOT (link_sets.content_id = ANY(found_links.content_id_path))
              AND #{link_type_condition}
          )
          SELECT array_to_json(content_id_path) as content_id_path, array_to_json(link_type_path) as link_type_path
          FROM found_links;
        SQL
      )
    end
  end
end
