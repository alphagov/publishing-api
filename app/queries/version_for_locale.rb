module Queries
  module VersionForLocale
    extend ArelHelpers

    def self.conflict(content_item_id, content_id, locale, user_facing_version)
      content_items_table = ContentItem.arel_table
      translations_table = Translation.arel_table
      user_facing_versions_table = UserFacingVersion.arel_table

      scope = content_items_table
        .project(content_items_table[:id])
        .join(translations_table).on(
          content_items_table[:id].eq(translations_table[:content_item_id])
        )
        .join(user_facing_versions_table).on(
          content_items_table[:id].eq(user_facing_versions_table[:content_item_id])
        )
        .where(content_items_table[:id].not_eq(content_item_id))
        .where(content_items_table[:content_id].eq(content_id))
        .where(translations_table[:locale].eq(locale))
        .where(user_facing_versions_table[:number].eq(user_facing_version))
        .order(content_items_table[:created_at].desc)
        .take(1)
      get_rows(scope).first.try(:symbolize_keys)
    end
  end
end
