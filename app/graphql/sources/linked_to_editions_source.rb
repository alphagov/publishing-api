module Sources
  class LinkedToEditionsSource < GraphQL::Dataloader::Source
    # rubocop:disable Lint/MissingSuper
    def initialize(content_store:)
      @content_store = content_store.to_sym
    end
    # rubocop:enable Lint/MissingSuper

    def fetch(editions_and_link_types_and_selections)
      edition_id_tuples = []
      content_id_tuples = []
      link_types_map = {}
      all_selections = Set.new(%i["links"."link_type"])

      editions_and_link_types_and_selections.each do |edition, link_type, selections|
        edition_id_tuples.push("(#{edition.id},'#{link_type}')")
        content_id_tuples.push("('#{edition.content_id}','#{link_type}')")
        link_types_map[[edition.content_id, link_type]] = []
        all_selections.merge(selections)
      end

      link_set_links_source_editions = Edition
        .joins(:document)
        .joins("INNER JOIN link_sets ON link_sets.content_id = documents.content_id")
        .joins("INNER JOIN links ON links.link_set_id = link_sets.id")
        .where(editions: { content_store: @content_store })
        .where(
          '("link_sets"."content_id", "links"."link_type") IN (?)',
          Arel.sql(content_id_tuples.join(",")),
        )
        .select(all_selections.to_a)
      # locale?
      # order?

      edition_links_source_editions = Edition
        .joins(:document, :links)
        .where(editions: { content_store: @content_store })
        .where(
          '("editions"."id", "links"."link_type") IN (?)',
          Arel.sql(edition_id_tuples.join(",")),
        )
        .select(all_selections.to_a)
      # locale?
      # order?

      # edition_links = Link
      #   .joins(edition: :document)
      #   .where('("editions"."id", "links"."link_type") IN (?)', Arel.sql(edition_id_tuples.join(",")))
      #   .order(link_type: :asc, position: :asc)
      #   .select("link_type", "target_content_id", "documents.content_id")

      # link_set_links = Link
      #   .joins(:link_set)
      #   .where('("link_sets"."content_id", "links"."link_type") IN (?)', Arel.sql(content_id_tuples.join(",")))
      #   .order(link_type: :asc, position: :asc)
      #   .select("link_type", "target_content_id", "link_sets.content_id")

      # all_links = edition_links + link_set_links

      # editions = Edition
      #   .joins(:document)
      #   .where(
      #     document: {
      #       locale: "en",
      #       content_id: all_links.map(&:target_content_id),
      #     },
      #     content_store: @content_store,
      #   )
      #   .select(all_selections.to_a)

      # editions_map = editions.index_by(&:content_id)

      all_editions = link_set_links_source_editions + edition_links_source_editions

      all_editions.each_with_object(link_types_map) { |edition, hash|
        hash[[edition.content_id, edition.link_type]] << edition
      }.values
    end
  end
end
