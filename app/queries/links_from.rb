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

      # links = links.where(editions: { content_store: "live" }) unless with_drafts

      links = links.where(link_type: allowed_link_types) if allowed_link_types

      links = links
        .where.not(target_content_id: parent_content_ids)
        .order(link_type: :asc, position: :asc)
        .pluck(:link_type, :target_content_id)

      grouped = links
        .group_by(&:first)
        .map { |type, values| [type.to_sym, values.map(&:last)] }

      Hash[grouped]
    end
  end
end
