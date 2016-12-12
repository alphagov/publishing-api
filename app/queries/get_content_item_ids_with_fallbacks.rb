module Queries
  class GetContentItemIdsWithFallbacks
    extend ArelHelpers

    def self.call(content_ids, locale_fallback_order: ContentItem::DEFAULT_LOCALE, state_fallback_order:)
      state_fallback_order = Array(state_fallback_order).map(&:to_s)
      locale_fallback_order = Array(locale_fallback_order).map(&:to_s)

      content_items = ContentItem.arel_table
      unpublishings = Unpublishing.arel_table

      fallback_scope = content_items.project(
        content_items[:id],
            content_items[:content_id],
          )
          .where(content_items[:content_id].in(content_ids))
          .where(content_items[:document_type].not_in(::ContentItem::NON_RENDERABLE_FORMATS))
          .where(content_items[:locale].in(locale_fallback_order))

      if state_fallback_order.include?("withdrawn")
        fallback_scope = fallback_scope.where(content_items[:state].in(state_fallback_order).or(content_items[:state]
                                                           .eq("unpublished")
                                                           .and(unpublishings[:type]
                                                                .eq("withdrawal"))))
        .join(unpublishings, Arel::Nodes::OuterJoin).on(unpublishings[:content_item_id].eq(content_items[:id]))
      else
        fallback_scope = fallback_scope.where(content_items[:state].in(state_fallback_order))
      end

      fallback_scope = fallback_scope.order(
        order_by_clause(:content_items, :state, state_fallback_order),
        order_by_clause(:content_items, :locale, locale_fallback_order)
      )

      fallbacks = cte(fallback_scope, as: "fallbacks")

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
