module Queries
  class GetDependees
    def call(content_id:, recursive_link_types: [], direct_link_types: [])
      (recursive_results(content_id, recursive_link_types) +
        direct_results(content_id, direct_link_types)).uniq
    end

  private

    def recursive_results(content_id, recursive_link_types)
      results(content_id, Array(recursive_link_types)).map do |result|
        result.fetch("target_content_id")
      end
    end

    def direct_results(content_id, direct_link_types)
      return [] if direct_link_types.empty?

      Link.joins(:link_set)
        .where("link_sets.content_id = ?", content_id)
        .where(link_type: direct_link_types)
        .pluck(:target_content_id)
    end

    # Finds all content_ids that are depended on by the given content_id. This query is
    # recursive and will also return content_ids that aren't direct neighbours
    # to the given content_id. This is called a 'transitive closure'.
    def results(content_id, link_types)
      return [] if link_types.empty?
      ActiveRecord::Base.connection.execute(
        <<-SQL
          WITH RECURSIVE dependees(target_content_id) AS (
            SELECT '#{content_id}'::TEXT
          UNION
            SELECT DISTINCT links.target_content_id
            FROM dependees
            JOIN link_sets
              ON link_sets.content_id = dependees.target_content_id
            JOIN links
              ON link_sets.id = links.link_set_id
             AND links.link_type in (#{quoted(link_types)})
          )
          SELECT DISTINCT target_content_id FROM dependees
          WHERE target_content_id != '#{content_id}'
        SQL
      )
    end

    def quoted(link_types)
      link_types.map { |s| "'#{s}'" }.join(",")
    end
  end
end
