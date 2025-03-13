module Sources
  class ReverseLinkedToEditionsSource < GraphQL::Dataloader::Source
    # rubocop:disable Lint/MissingSuper
    def initialize(content_store:)
      @content_store = content_store.to_sym
    end
    # rubocop:enable Lint/MissingSuper

    def fetch(editions_and_link_types)
      all_selections = {
        links: %i[target_content_id link_type link_set_id edition_id],
        documents: %i[content_id],
      }
      content_id_tuples = []
      link_types_map = {}

      editions_and_link_types.each do |edition, link_type|
        content_id_tuples.push("('#{edition.content_id}','#{link_type}')")
        link_types_map[[edition.content_id, link_type]] = []
      end

      link_set_links_source_editions = Edition
        .joins(:document)
        .joins("INNER JOIN link_sets ON link_sets.content_id = documents.content_id")
        .joins("INNER JOIN links ON links.link_set_id = link_sets.id")
        .where(editions: { content_store: @content_store })
        .where(
          '("links"."target_content_id", "links"."link_type") IN (?)',
          Arel.sql(content_id_tuples.join(",")),
        )
        .select("editions.*", all_selections)

      edition_links_source_editions = Edition
        .joins(:document, :links)
        .where(editions: { content_store: @content_store })
        .where(
          '("links"."target_content_id", "links"."link_type") IN (?)',
          Arel.sql(content_id_tuples.join(",")),
        )
        .select("editions.*", all_selections)

      all_editions = Edition.from(
        <<~SQL,
          (
            #{link_set_links_source_editions.to_sql}
            UNION
            #{edition_links_source_editions.to_sql}
          ) AS editions
        SQL
      )

      all_editions.each_with_object(link_types_map) { |edition, hash|
        hash[[edition.target_content_id, edition.link_type]] << edition
      }.values
    end
  end
end
