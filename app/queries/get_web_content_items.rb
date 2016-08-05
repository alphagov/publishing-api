module Queries
  class GetWebContentItems
    extend ArelHelpers

    def self.call(content_item_ids)
      content_items = table(:content_items)

      get_rows(scope.where(content_items[:id].in(content_item_ids))).map do |row|
        WebContentItem.from_hash(row)
      end
    end

    def self.find(content_item_id)
      call(content_item_id).first
    end

    def self.scope
      content_items = table(:content_items)
      locations = table(:locations)
      states = table(:states)
      translations = table(:translations)
      user_facing_versions = table(:user_facing_versions)

      content_items
        .project(
          content_items[:id],
          content_items[:analytics_identifier],
          content_items[:content_id],
          content_items[:description],
          content_items[:details],
          content_items[:document_type],
          content_items[:first_published_at],
          content_items[:last_edited_at],
          content_items[:need_ids],
          content_items[:phase],
          content_items[:public_updated_at],
          content_items[:publishing_app],
          content_items[:redirects],
          content_items[:rendering_app],
          content_items[:routes],
          content_items[:schema_name],
          content_items[:title],
          content_items[:update_type],
          locations[:base_path],
          states[:name].as("state"),
          translations[:locale],
          user_facing_versions[:number].as("user_facing_version")
        )
        .outer_join(locations).on(content_items[:id].eq(locations[:content_item_id]))
        .join(states).on(content_items[:id].eq(states[:content_item_id]))
        .join(translations).on(content_items[:id].eq(translations[:content_item_id]))
        .join(user_facing_versions).on(content_items[:id].eq(user_facing_versions[:content_item_id]))
    end
  end
end
