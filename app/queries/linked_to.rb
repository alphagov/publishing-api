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

  private

    def linked_to(content_id, expansion_rules)
      all_results = results(content_id, expansion_rules.recursive_link_types)
      # This weeds out full matches from partial matches
      filtered = all_results.select do |result|
        link_type_path = JSON.parse(result["link_type_path"]).reverse
        link_type_path.count == 1 || expansion_rules.valid_link_recursion?(link_type_path)
      end
      filtered.map { |result| JSON.parse(result["content_id_path"]) }.flatten.uniq
    end

    # FIXME: It would be nicer to have a variable that represented depth and
    # appended array in the recursive part of this query rather than having
    # to append and increment the depth in the WHERE conditions.
    def results(content_id, recursive_link_types)
      connection.execute(
        <<-SQL
          WITH RECURSIVE found_links (
            content_id, link_type_path, content_id_path, depth
          ) AS (
            -- All links which target this content item
            SELECT
              link_sets.content_id,
              ARRAY[links.link_type],
              ARRAY[link_sets.content_id],
              1
            FROM link_sets
            INNER JOIN links
              ON link_sets.id = links.link_set_id
            WHERE links.target_content_id = #{connection.quote(content_id)}
          UNION
            -- Recursive links which target a link we have found
            -- and is not one of the parents of this link (to avoid a cycle)
            -- and matches one of the paths we accept.
            -- As it's recursive it will match partial items, these are
            -- filtered afterwards.
            SELECT
              link_sets.content_id,
              link_type_path || links.link_type,
              content_id_path || link_sets.content_id,
              depth + 1
            FROM found_links
            JOIN links
              ON links.target_content_id = found_links.content_id
            JOIN link_sets
              ON link_sets.id = links.link_set_id
            WHERE NOT (link_sets.content_id = ANY(content_id_path))
              AND (#{valid_link_types_condition(recursive_link_types)})
          )
          SELECT array_to_json(content_id_path) as content_id_path,
            array_to_json(link_type_path) as link_type_path
          FROM found_links;
        SQL
      )
    end

    def valid_link_types_condition(recursive_link_types)
      return "1 = 0" if recursive_link_types.empty?
      "#{non_sticky_valid_paths(recursive_link_types)} OR #{sticky_valid_paths(recursive_link_types)}"
    end

    # This matches all the types of non sticky paths a link type could have
    # a path is deemed non sticky if it doesn't have the last element repeating
    # e.g. :mainstream_browse_pages, :parent is non sticky
    # whereas :mainstream_browse_pages, :parent, :parent is sticky
    # It returned an SQL IN condition:
    # (links_type_path || links.link_type)::text[] IN (ARRAY['parent', 'mainstream_browse_pages'])
    def non_sticky_valid_paths(recursive_link_types)
      paths = recursive_link_types.map(&:reverse).flat_map do |types|
        all_combinations = (2..types.length).flat_map { |n| types.combination(n).to_a }
        combinations = all_combinations.select { |c| combination_inside_array(c, types) }
        combinations.map { |c| quote_array(c) }
      end
      paths.present? ? "(link_type_path || links.link_type)::text[] IN (#{paths.join(',')})" : "1 = 0"
    end

    # This matches sticky valid paths, so this creates a collection of SQL
    # conditions which check the suffix of the link_type_paths match one
    # of the valid sticky link type paths
    # an example output would be
    # ((link_type_path || links.link_type)::text[])[(depth + 1 - 2):(depth + 1)] IN (ARRAY['parent', 'parent'])
    def sticky_valid_paths(recursive_link_types)
      paths = recursive_link_types.map(&:reverse).flat_map do |types|
        types.inject([]) do |memo, item|
          memo.empty? ? [[types.first, item]] : memo << (memo.last + [item])
        end
      end
      conditions = paths.uniq.group_by(&:length).map do |length, paths_of_length|
        in_array = paths_of_length.map { |path| quote_array(path) }.join(",")
        "((link_type_path || links.link_type)::text[])[(depth + 1 - #{length - 1}):(depth + 1)] IN (#{in_array})"
      end
      conditions.join(" OR ")
    end

    def connection
      ActiveRecord::Base.connection
    end

    def quote_array(array)
      quoted = array.map { |s| connection.quote(s) }.join(",")
      "ARRAY[#{quoted}]"
    end

    def combination_inside_array(combination, array)
      # FIXME: I want to do the equivalent of "str".include?("st") but with
      # arrays but I don't know a nice method to do it. Please fix if you know
      # a nicer way
      index_sequence = combination.map { |value| array.index(value) }
      first_index = index_sequence[0]
      last_index = first_index + (combination.length - 1)
      index_sequence == (first_index..last_index).to_a
    end
  end
end
