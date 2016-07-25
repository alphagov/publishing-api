module Queries
  module ContentItemUniqueness
    extend ArelHelpers
    extend self

    def unique_fields_for_content_item(content_item)
      scope = unique_fields_scope
      scope
        .where(table(:content_items)[:id].eq(content_item.id))
        .take(1)
      get_rows(scope).first.try(:symbolize_keys)
    end

    def first_non_unique_item(content_item, base_path:, locale:, state:, user_facing_version:)
      scope = unique_fields_scope
      scope
        .where(table(:content_items)[:id].not_eq(content_item.id))
        .where(table(:states)[:name].eq(state))
        .where(table(:translations)[:locale].eq(locale))
        .where(table(:locations)[:base_path].eq(base_path))
        .where(table(:user_facing_versions)[:number].eq(user_facing_version))
        .take(1)
      get_rows(scope).first.try(:symbolize_keys)
    end

    def unique_fields_scope
      content_items_table = table(:content_items)
      states_table = table(:states)
      translations_table = table(:translations)
      locations_table = table(:locations)
      user_facing_versions_table = table(:user_facing_versions)

      content_items_table
        .project(
          content_items_table[:content_id],
          states_table[:name].as("state"),
          translations_table[:locale],
          locations_table[:base_path],
          user_facing_versions_table[:number].as("user_facing_version")
        )
        .outer_join(states_table).on(
          content_items_table[:id].eq(states_table[:content_item_id])
        )
        .outer_join(translations_table).on(
          content_items_table[:id].eq(translations_table[:content_item_id])
        )
        .outer_join(locations_table).on(
          content_items_table[:id].eq(locations_table[:content_item_id])
        )
        .outer_join(user_facing_versions_table).on(
          content_items_table[:id].eq(user_facing_versions_table[:content_item_id])
        )
    end

    private_class_method :unique_fields_scope
  end
end
