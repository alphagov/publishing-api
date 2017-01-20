module Queries
  class GetContentItemIdsWithFallbacks
    def self.call(content_ids, state_fallback_order:, locale_fallback_order: ContentItem::DEFAULT_LOCALE)
      state_fallback_order = Array.wrap(state_fallback_order).map(&:to_s)
      locale_fallback_order = Array.wrap(locale_fallback_order).map(&:to_s)

      ContentItem.joins(:document).left_outer_joins(:unpublishing)
        .where(documents: { content_id: content_ids })
        .where(where_state(state_fallback_order))
        .where(documents: { locale: locale_fallback_order })
        .where.not(document_type: ContentItem::NON_RENDERABLE_FORMATS)
        .order("documents.content_id ASC")
        .order(order_by_clause("content_items", "state", state_ordering(state_fallback_order)))
        .order(order_by_clause("documents", "locale", locale_fallback_order))
        .pluck("DISTINCT ON (documents.content_id) documents.content_id, content_items.id")
        .map(&:last)
    end

    def self.where_state(state_fallback_order)
      without_withdrawn = state_fallback_order - ["withdrawn"]
      if without_withdrawn.present?
        state_check = ContentItem.arel_table[:state].in(without_withdrawn)
      else
        state_check = nil
      end

      if state_fallback_order.include?("withdrawn")
        withdrawn_check = ContentItem.arel_table[:state].eq("unpublished")
                            .and(Unpublishing.arel_table[:type].eq("withdrawal"))
      else
        withdrawn_check = nil
      end

      if state_check && withdrawn_check
        state_check.or(withdrawn_check)
      else
        state_check || withdrawn_check
      end
    end
    private_class_method :where_state

    def self.order_by_clause(table, attribute, values)
      sql = %{CASE "#{table}"."#{attribute}" }
      sql << values.map.with_index { |v, i| "WHEN '#{v}' THEN #{i}" }.join(" ")
      sql << " ELSE #{values.size} END"
    end
    private_class_method :order_by_clause

    # We have a special case where a state of withdrawn can be passed in,
    # this is not actually a state but an unpublishing type. So when this is
    # passed in it is changed to "unpublished" for ordering purposes.
    def self.state_ordering(state_fallback_order)
      state_fallback_order.map { |state| state == "withdrawn" ? "unpublished" : state }
    end
    private_class_method :state_ordering
  end
end
