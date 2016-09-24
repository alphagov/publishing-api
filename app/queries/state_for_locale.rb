module Queries
  module StateForLocale
    extend ArelHelpers

    def self.conflict(content_item_id, content_id, state, locale)
      return if state == "superseded"

      content_items_table = ContentItem.arel_table
      translations_table = Translation.arel_table
      states_table = State.arel_table

      if state == "draft"
        state_condition = states_table[:name].eq("draft")
      else
        state_condition = states_table[:name].in(%w(published unpublished))
      end

      scope = content_items_table
        .project(content_items_table[:id])
        .join(states_table).on(
          content_items_table[:id].eq(states_table[:content_item_id])
        )
        .join(translations_table).on(
          content_items_table[:id].eq(translations_table[:content_item_id])
        )
        .where(content_items_table[:id].not_eq(content_item_id))
        .where(content_items_table[:content_id].eq(content_id))
        .where(state_condition)
        .where(translations_table[:locale].eq(locale))
        .order(content_items_table[:created_at].desc)
        .take(1)
      get_rows(scope).first.try(:symbolize_keys)
    end
  end
end
