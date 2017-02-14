module Queries
  class LinksFrom
    def self.call(content_id, with_drafts:, locales:, allowed_link_types: nil, parent_content_ids: [])
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
        .pluck(:link_type, :target_content_id, :content_store, :locale)

      # these checks have to happen outside of the SQL as the queries only
      # apply to edition-level links
      links.select! { |item| item[2] != "draft" } unless with_drafts
      links.select! { |item| (locales + [nil]).include?(item[3]) } if locales.present?

      grouped = links
        .group_by(&:first)
        .map { |type, values| [type.to_sym, values.map { |item| item[1] }] }

      Hash[grouped]
    end
  end
end
