module Queries
  module GetLatest
    class << self
      # Returns a new scope for the content items with the highest user-facing
      # version number per content_id and locale of the given scope.
      def call(content_item_scope)
        scope = content_item_scope.select(:id, :content_id, 'content_items.locale', :user_facing_version)

        ContentItem.joins <<-SQL
          INNER JOIN (
            WITH scope AS (#{scope.to_sql})
            SELECT s1.id FROM scope s1
            LEFT OUTER JOIN scope s2 ON
              s1.content_id = s2.content_id AND
              s1.locale = s2.locale AND
              s1.user_facing_version < s2.user_facing_version
            WHERE s2.content_id IS NULL
          ) AS latest_versions
          ON latest_versions.id = content_items.id
        SQL
      end
    end
  end
end
