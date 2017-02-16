module Queries
  class LinksFrom
    def self.call(content_id, with_drafts:, locale:, allowed_link_types: nil, parent_content_ids: [])
      return {} if allowed_link_types && allowed_link_types.empty?

      links = Link
        .left_outer_joins(:link_set)
        .left_outer_joins(edition: :document)

      links = links
        .where("link_sets.content_id = ? OR documents.content_id = ?",
               content_id, content_id)

      if with_drafts
        has_draft = "EXISTS (SELECT 1
                             FROM editions AS e
                             WHERE content_store = 'draft'
                               AND e.document_id = documents.id)"
        links = links.where("editions.content_store IS NULL
                             OR CASE
                               WHEN #{has_draft}
                                 THEN editions.content_store = 'draft'
                               ELSE editions.content_store = 'live'
                             END")
      else
        links = links.where(editions: { content_store: [nil, "live"] })
      end

      if locale.nil?
        links = links.where(documents: { locale: nil })
      else
        links = links.where(documents: { locale: [nil, locale] })
      end

      links = links.where(link_type: allowed_link_types) if allowed_link_types

      links = links
        .where.not(target_content_id: parent_content_ids + [content_id])
        .order(link_type: :asc, position: :asc)
        .pluck(:link_type, :target_content_id)

      grouped = links
        .group_by(&:first)
        .map { |type, values| [type.to_sym, values.map { |item| item[1] }] }

      Hash[grouped]
    end
  end
end
