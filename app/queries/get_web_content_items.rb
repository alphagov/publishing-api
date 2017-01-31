module Queries
  class GetWebContentItems
    extend ArelHelpers

    def self.call(edition_ids, presenter = WebContentItem)
      editions = Edition.arel_table
      filtered = scope.where(editions[:id].in(edition_ids))
      get_rows(filtered).map do |row|
        presenter.from_hash(row)
      end
    end

    def self.find(edition_id)
      call(edition_id).first
    end

    def self.for_content_store(content_id, locale, include_draft = false)
      documents = Document.arel_table
      editions = Edition.arel_table
      unpublishings = Unpublishing.arel_table

      allowed_states = [:published, :unpublished]
      allowed_states << :draft if include_draft
      filtered = scope(editions[:user_facing_version].desc)
        .where(documents[:content_id].eq(content_id))
        .where(documents[:locale].eq(locale))
        .where(editions[:state].in(allowed_states))
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
      editions = Edition.arel_table
      unpublishings = Unpublishing.arel_table

      editions
        .project(
          editions[:id],
          editions[:analytics_identifier],
          documents[:content_id],
          editions[:description],
          editions[:details],
          editions[:document_type],
          editions[:first_published_at],
          editions[:last_edited_at],
          editions[:need_ids],
          editions[:phase],
          editions[:public_updated_at],
          editions[:publishing_app],
          editions[:redirects],
          editions[:rendering_app],
          editions[:routes],
          editions[:schema_name],
          editions[:title],
          editions[:update_type],
          editions[:base_path],
          editions[:state],
          documents[:locale],
          editions[:user_facing_version],
          unpublishings[:type].as("unpublishing_type")
        )
        .join(documents).on(editions[:document_id].eq(documents[:id]))
        .outer_join(unpublishings).on(
          editions[:id].eq(unpublishings[:edition_id])
            .and(editions[:state].eq("unpublished"))
        )
        .order(order || editions[:id].asc)
    end
  end
end
