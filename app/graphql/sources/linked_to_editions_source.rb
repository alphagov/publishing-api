module Sources
  class LinkedToEditionsSource < GraphQL::Dataloader::Source
    # rubocop:disable Lint/MissingSuper
    def initialize(content_store:, locale:)
      @content_store = content_store.to_sym
      @primary_locale = locale
      @locale_with_fallback = [locale, Edition::DEFAULT_LOCALE].uniq
    end
    # rubocop:enable Lint/MissingSuper

    def fetch(editions_and_link_types)
      all_selections = {
        links: {
          link_type: :link_type,
          position: :position,
          id: :link_id,
        },
        documents: %i[content_id locale],
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
          documents: { locale: @locale_with_fallback },
        )
        .where.not(editions: { document_type: Edition::NON_RENDERABLE_FORMATS })
        .where(
          %["links"."link_type" IN (?) OR "editions"."state" != 'unpublished'],
          Link::PERMITTED_UNPUBLISHED_LINK_TYPES,
        )
        .select(
          "editions.*",
          all_selections,
          { link_sets: { content_id: :source_content_id } },
          Arel.sql(
            <<~SQL,
              row_number() OVER (
                PARTITION BY "documents"."content_id", "links"."link_type", "link_sets"."content_id"
                ORDER BY (
                  CASE
                    WHEN ("documents"."locale" = ?) THEN 0
                    ELSE 1
                  END
                )
              )
            SQL
            @primary_locale,
          ),
          "'link_set_link' AS link_kind",
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
          documents: { locale: @locale_with_fallback },
        )
        .where.not(editions: { document_type: Edition::NON_RENDERABLE_FORMATS })
        .where(
          %["links"."link_type" IN (?) OR "editions"."state" != 'unpublished'],
          Link::PERMITTED_UNPUBLISHED_LINK_TYPES,
        )
        .select(
          "editions.*",
          all_selections,
          { source_documents: { content_id: :source_content_id } },
          Arel.sql(
            <<~SQL,
              row_number() OVER (
                PARTITION BY "documents"."content_id", "links"."link_type", "source_editions"."id"
                ORDER BY (
                  CASE
                    WHEN ("documents"."locale" = ?) THEN 0
                    ELSE 1
                  END
                )
              )
            SQL
            @primary_locale,
            "'edition_link' AS link_kind",
          ),
        )

      all_editions = Edition
        .from(
          <<~SQL,
            (
              #{link_set_links_target_editions.to_sql}
              UNION ALL
              #{edition_links_target_editions.to_sql}
            ) AS editions
          SQL
        )
        .where(editions: { row_number: 1 })
        .order(link_type: :asc, position: :asc, link_id: :desc)

      all_editions.each_with_object(link_types_map) { |edition, hash|
        unless hash[[edition.source_content_id, edition.link_type]].include?(edition)
          hash[[edition.source_content_id, edition.link_type]] << edition
        end
      }.values
    end
  end
end
