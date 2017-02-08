module Queries
  class LinksFrom
    def self.call(content_id, with_drafts:, allowed_link_types: nil, parent_content_ids: [])
      return {} if allowed_link_types && allowed_link_types.empty?

      links = Link
        .left_outer_joins(:link_set)
        .left_outer_joins(edition: :document)

      links = links
        .where("link_sets.content_id = ? OR documents.content_id = ?",
               content_id, content_id)

      links = links.where(link_type: allowed_link_types) if allowed_link_types

      links = links
        .where.not(target_content_id: parent_content_ids + [content_id])
        .order(link_type: :asc, position: :asc)
        .pluck(:link_type, :target_content_id, :content_store)

      links.select! { |item| item.last != "draft" } unless with_drafts

      grouped = links
        .group_by(&:first)
        .map { |type, values| [type.to_sym, values.map { |item| item[1] }] }

      Hash[grouped]
    end
  end
end
