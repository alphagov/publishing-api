module Sources
  class ReverseLinkedToEditionsSource < GraphQL::Dataloader::Source
    # rubocop:disable Lint/MissingSuper
    def initialize(content_store:, locale:)
      @content_store = content_store.to_sym
      @primary_locale = locale
      @locale_with_fallback = [locale, Edition::DEFAULT_LOCALE].uniq
    end
    # rubocop:enable Lint/MissingSuper

    def fetch(editions_and_link_types)
      all_selections = {
        links: %i[target_content_id link_type edition_id position],
        documents: %i[content_id],
      }
      row_number_selection = Arel.sql(
        <<~SQL,
          row_number() OVER (
            PARTITION BY "documents"."content_id", "links"."link_type", "links"."target_content_id"
            ORDER BY (
              CASE
                WHEN ("documents"."locale" = ?) THEN 0
                ELSE 1
              END
            )
          )
        SQL
        @primary_locale,
      )
      content_id_tuples = []
      link_types_map = {}

      editions_and_link_types.each do |edition, link_type|
        content_id_tuples.push("('#{edition.content_id}','#{link_type}')")
        link_types_map[[edition.content_id, link_type]] = []
      end

      link_set_links_source_editions = Edition
        .joins(:document)
        .joins("INNER JOIN links ON links.link_set_content_id = documents.content_id")
        .where(
          editions: { content_store: @content_store },
          documents: { locale: @locale_with_fallback },
        )
        .where.not(editions: { document_type: Edition::NON_RENDERABLE_FORMATS })
        .where(
          '("links"."target_content_id", "links"."link_type") IN (?)',
          Arel.sql(content_id_tuples.join(",")),
        )
        .where(
          %["links"."link_type" IN (?) OR "editions"."state" != 'unpublished'],
          Link::PERMITTED_UNPUBLISHED_LINK_TYPES,
        )
        .select(
          "editions.*",
          all_selections,
          row_number_selection,
        )

      edition_links_source_editions = Edition
        .joins(:document, :links)
        .where(
          editions: { content_store: @content_store },
          documents: { locale: @locale_with_fallback },
        )
        .where.not(editions: { document_type: Edition::NON_RENDERABLE_FORMATS })
        .where(
          '("links"."target_content_id", "links"."link_type") IN (?)',
          Arel.sql(content_id_tuples.join(",")),
        )
        .where(
          %["links"."link_type" IN (?) OR "editions"."state" != 'unpublished'],
          Link::PERMITTED_UNPUBLISHED_LINK_TYPES,
        )
        .select(
          "editions.*",
          all_selections,
          row_number_selection,
        )

      all_editions = Edition.from(
        <<~SQL,
          (
            #{link_set_links_source_editions.to_sql}
            UNION
            #{edition_links_source_editions.to_sql}
          ) AS editions
        SQL
      )
        .where(editions: { row_number: 1 })
        .order(link_type: :asc, position: :asc, id: :asc)

      all_editions.each_with_object(link_types_map) { |edition, hash|
        unless hash[[edition.target_content_id, edition.link_type]].include?(edition)
          hash[[edition.target_content_id, edition.link_type]] << edition
        end
      }.values
    end
  end
end
