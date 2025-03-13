module Sources
  class LinkedToEditionsSource < GraphQL::Dataloader::Source
    # rubocop:disable Lint/MissingSuper
    def initialize(content_store:)
      @content_store = content_store.to_sym
    end
    # rubocop:enable Lint/MissingSuper

    def fetch(editions_and_link_types)
      all_selections = {
        links: %i[link_type position],
        documents: %i[content_id],
      }
      edition_id_tuples = []
      content_id_tuples = []
      link_types_map = {}

      editions_and_link_types.each do |edition, link_type|
        edition_id_tuples.push("(#{edition.id},'#{link_type}')")
        content_id_tuples.push("('#{edition.content_id}','#{link_type}')")
        link_types_map[[edition.content_id, link_type]] = []
      end

      link_set_links_target_editions = Edition
        .joins(document: { reverse_links: :link_set })
        .where(
          '("link_sets"."content_id", "links"."link_type") IN (?)',
          Arel.sql(content_id_tuples.join(",")),
        )
        .where(
          editions: { content_store: @content_store },
          documents: { locale: "en" },
        )
        .select(
          "editions.*",
          all_selections,
          { link_sets: { content_id: :source_content_id } },
        )

      edition_links_target_editions = Edition
        .joins(document: :reverse_links)
        .joins(
          <<~SQL,
            INNER JOIN editions source_editions
            ON source_editions.id = links.edition_id
          SQL
        )
        .joins(
          <<~SQL,
            INNER JOIN documents source_documents
            ON source_documents.id = source_editions.document_id
          SQL
        )
        .where(
          '("source_editions"."id", "links"."link_type") IN (?)',
          Arel.sql(edition_id_tuples.join(",")),
        )
        .where(
          editions: { content_store: @content_store },
          documents: { locale: "en" },
        )
        .select(
          "editions.*",
          all_selections,
          { source_documents: { content_id: :source_content_id } },
        )

      all_editions = Edition
        .from(
          <<~SQL,
            (
              #{link_set_links_target_editions.to_sql}
              UNION
              #{edition_links_target_editions.to_sql}
            ) AS editions
          SQL
        )
        .order(link_type: :asc, position: :asc)

      all_editions.each_with_object(link_types_map) { |edition, hash|
        hash[[edition.source_content_id, edition.link_type]] << edition
      }.values
    end
  end
end
