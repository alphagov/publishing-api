module Queries
  module GetDependents
    # Finds all content_ids that depend on the given content_id. This query is
    # recursive and will also return content_ids that aren't direct neighbours
    # to the given content_id. This is called a 'transitive closure'.
    #
    # If the optional link_type is given, only links that have that link_type
    # will be followed when computing dependencies.
    def self.call(content_id, link_type = nil)
      results = ActiveRecord::Base.connection.execute(
        <<-SQL
          WITH RECURSIVE dependents(content_id, link_type) AS (
            SELECT '#{content_id}'::TEXT, '#{link_type}'
          UNION
              SELECT DISTINCT link_sets.content_id, dependents.link_type
              FROM dependents
              JOIN links
                ON links.target_content_id = dependents.content_id
            #{'AND links.link_type = dependents.link_type' if link_type}
              JOIN link_sets
                ON link_sets.id = links.link_set_id
          )
          SELECT DISTINCT content_id FROM dependents
          WHERE content_id != '#{content_id}'
        SQL
      )

      results.map { |r| r.fetch("content_id") }
    end
  end
end
