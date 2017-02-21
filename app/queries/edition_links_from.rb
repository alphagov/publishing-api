module Queries
  class EditionLinksFrom
    def self.call(content_id, with_drafts:, locale:, allowed_link_types: nil)
      return {} if allowed_link_types && allowed_link_types.empty?

      links = Link
        .left_joins(edition: :document)
        .where(documents: { content_id: content_id })

      links = links.where(documents: { locale: locale }) if locale
      links = links.where(link_type: allowed_link_types) if allowed_link_types

      if with_drafts
        where_sql = <<-SQL.strip_heredoc
          CASE WHEN EXISTS (SELECT 1 FROM editions AS e
                            WHERE content_store = 'draft'
                            AND e.document_id = documents.id)
               THEN editions.content_store = 'draft'
               ELSE editions.content_store = 'live'
          END
        SQL

        links = links.where(where_sql)
      else
        links = links.where(editions: { content_store: "live" })
      end

      links = links
        .order(link_type: :asc, position: :asc)
        .pluck(:link_type, :target_content_id, "documents.locale", "editions.id")

      grouped = links
        .group_by(&:first)
        .map { |type, values| [type.to_sym, values.map { |item| item.drop(1) }] }

      Hash[grouped]
    end
  end
end
