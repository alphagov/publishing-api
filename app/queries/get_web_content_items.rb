module Queries
  class GetWebContentItems
    extend ArelHelpers

    def self.call(content_item_ids, presenter = WebContentItem)
      content_items = ContentItem.arel_table
      filtered = scope
        .where(content_items[:id].in(content_item_ids))
      get_rows(filtered).map do |row|
        presenter.from_hash(row)
      end
    end

    def self.find(content_item_id)
      call(content_item_id).first
    end

    def self.for_content_store(content_id, locale, include_draft = false)
      documents = Document.arel_table
      content_items = ContentItem.arel_table
      unpublishings = Unpublishing.arel_table

      allowed_states = [:published, :unpublished]
      allowed_states << :draft if include_draft
      filtered = scope(content_items[:user_facing_version].desc)
        .where(documents[:content_id].eq(content_id))
        .where(documents[:locale].eq(locale))
        .where(content_items[:state].in(allowed_states))
        .where(
          unpublishings[:type].eq(nil).or(
            unpublishings[:type].not_eq("substitute")
          )
        )
        .take(1)
      results = get_rows(filtered).map do |row|
        WebContentItem.from_hash(row)
      end
      results.first
    end

    def self.scope(order = nil)
      documents = Document.arel_table
      content_items = ContentItem.arel_table
      unpublishings = Unpublishing.arel_table

      content_items
        .project(
          content_items[:id],
          content_items[:analytics_identifier],
          documents[:content_id],
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
          content_items[:base_path],
          content_items[:state],
          documents[:locale],
          content_items[:user_facing_version],
          unpublishings[:type].as("unpublishing_type")
        )
        .join(documents).on(content_items[:document_id].eq(documents[:id]))
        .outer_join(unpublishings).on(
          content_items[:id].eq(unpublishings[:content_item_id])
            .and(content_items[:state].eq("unpublished"))
        )
        .order(order || content_items[:id].asc)
    end
  end
end
