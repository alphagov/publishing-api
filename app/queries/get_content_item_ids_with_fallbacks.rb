module Queries
  class GetContentItemIdsWithFallbacks
    extend ArelHelpers

    def self.call(content_ids, locale_fallback_order: ContentItem::DEFAULT_LOCALE, state_fallback_order:)
      state_fallback_order = Array(state_fallback_order).map(&:to_s)
      locale_fallback_order = Array(locale_fallback_order).map(&:to_s)

      content_items = table(:content_items)
      states = table(:states)
      translations = table(:translations)

      fallbacks = cte(
        content_items.project(
          content_items[:id],
            content_items[:content_id],
          )
          .join(states).on(states[:content_item_id].eq(content_items[:id]))
          .join(translations).on(translations[:content_item_id].eq(content_items[:id]))
          .where(content_items[:content_id].in(content_ids))
          .where(states[:name].in(state_fallback_order))
          .where(translations[:locale].in(locale_fallback_order))
          .order(
            order_by_clause(:states, :name, state_fallback_order),
            order_by_clause(:translations, :locale, locale_fallback_order)
          ),
        as: "fallbacks"
      )

      aggregates = cte(
        fallbacks.table
          .project(Arel::Nodes::NamedFunction.new("array_agg", [fallbacks.table[:id]], "ids"))
          .group(fallbacks.table[:content_id])
          .with(fallbacks.compiled_scope),
        as: "aggregates"
      )

      get_column(
        aggregates.table
          .project(Arel::Nodes::SqlLiteral.new('aggregates.ids[1] AS id'))
          .with(aggregates.compiled_scope)
          .to_sql
      )
    end

    # Arel::Nodes::Case is coming in arel master
    def self.order_by_clause(table, attribute, values)
      sql = %{CASE "#{table}"."#{attribute}" }
      sql << values.map.with_index { |v, i| "WHEN '#{v}' THEN #{i}" }.join(" ")
      sql << " ELSE #{values.size} END"
      Arel::Nodes::SqlLiteral.new(sql)
    end
    private_class_method :order_by_clause
  end
end
