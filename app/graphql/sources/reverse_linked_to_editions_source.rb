module Sources
  class ReverseLinkedToEditionsSource < GraphQL::Dataloader::Source
    # rubocop:disable Lint/MissingSuper
    def initialize(content_store:)
      @content_store = content_store.to_sym
    end
    # rubocop:enable Lint/MissingSuper

    def fetch(editions_and_link_types)
      all_selections = {
        links: %i[target_content_id link_type edition_id],
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
        .joins("INNER JOIN links ON links.link_set_content_id = documents.content_id")
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
      ).order("editions.id")

      all_editions.each_with_object(link_types_map) { |edition, hash|
        next if edition.state == "unpublished" && %w[children parent related_statistical_data_sets].exclude?(edition.link_type)

        hash[[edition.target_content_id, edition.link_type]] << edition
      }.values
    end
  end
end
