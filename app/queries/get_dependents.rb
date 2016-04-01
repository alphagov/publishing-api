module Queries
  class GetDependents
    def call(content_id:,
             recursive_link_types: [],
             direct_link_types: [])
      (recursive_results(content_id, recursive_link_types) +
        direct_results(content_id, direct_link_types)).uniq
    end

  private

    def recursive_results(content_id, recursive_link_types)
      results(content_id, Array(recursive_link_types)).map do |result|
        result.fetch("content_id")
      end
    end

    def direct_results(content_id, direct_link_types)
      return [] if direct_link_types.empty?
      LinkSet.joins(:links)
        .where("links.target_content_id = ?", content_id)
        .where("links.link_type IN (?)", direct_link_types)
        .map(&:content_id)
    end

    # Finds all content_ids that depend on the given content_id. This query is
    # recursive and will also return content_ids that aren't direct neighbours
    # to the given content_id. This is called a 'transitive closure'.
    def results(content_id, link_types)
      return [] if link_types.empty?
      ActiveRecord::Base.connection.execute(
        <<-SQL
          WITH RECURSIVE dependents(content_id) AS (
            SELECT '#{content_id}'::TEXT
          UNION
            SELECT DISTINCT link_sets.content_id
            FROM dependents
            JOIN links
              ON links.target_content_id = dependents.content_id
             AND links.link_type in (#{quoted(link_types)})
            JOIN link_sets
              ON link_sets.id = links.link_set_id
          )
          SELECT DISTINCT content_id FROM dependents
          WHERE content_id != '#{content_id}'
        SQL
      )
    end

    def quoted(link_types)
      link_types.map { |s| "'#{s}'" }.join(",")
    end
  end
end
