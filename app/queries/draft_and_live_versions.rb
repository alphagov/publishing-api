module Queries
  module DraftAndLiveVersions
    extend ArelHelpers
    def self.call(content_item, target_table_name, locale = nil)
      content_items_table = table(:content_items)
      states_table = table(:states)
      translations_table = table(:translations)
      versions_table = table(target_table_name)
      versions_fk = target_table_name == "lock_versions" ? :target_id : :content_item_id

      if locale.nil?
        locale = translations_table.project(translations_table[:locale])
          .where(translations_table[:content_item_id].eq(content_item.id))
      end

      scope = content_items_table
        .project(
          Arel::Nodes::SqlLiteral.new(
            "CASE WHEN states.name IN ('published', 'unpublished') THEN 'live' " +
            "WHEN states.name = 'draft' THEN 'draft' END"
          ).as("state"),
          versions_table[:number].as("version_number")
        )
        .join(states_table).on(
          content_items_table[:id].eq(states_table[:content_item_id])
        )
        .join(translations_table).on(
          content_items_table[:id].eq(translations_table[:content_item_id])
        )
        .join(versions_table).on(
          content_items_table[:id].eq(versions_table[versions_fk])
        )
        .where(content_items_table[:content_id].eq(content_item.content_id))
        .where(translations_table[:locale].eq(locale))
        .where(states_table[:name].in(%w(draft published unpublished)))
      if target_table_name == "lock_versions"
        scope.where(versions_table[:target_type].eq("ContentItem"))
      end

      cte = Arel::Table.new("cte")
      left = cte
        .project(
          cte[:state],
          cte[:version_number]
        )
        .where(cte[:state].eq("draft"))
        .order(cte[:version_number].desc)
        .take(1)
      right = cte
        .project(
          cte[:state],
          cte[:version_number]
        )
        .where(cte[:state].eq("live"))
        .order(cte[:version_number].desc)
        .take(1)

      # Arel doesn't correctly add parens around complex UNION clauses, which
      # Postgres requires, so we need to build up the SQL query manually.
      query = "WITH cte AS (#{scope.to_sql}) (#{left.to_sql}) UNION (#{right.to_sql})"

      Hash[get_rows(query).map { |i| [i["state"], i["version_number"].to_i] }]
    end
  end
end
