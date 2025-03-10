module Sources
  class LinkedToEditionsSource < GraphQL::Dataloader::Source
    # rubocop:disable Lint/MissingSuper
    def initialize(content_store:)
      @content_store = content_store.to_sym
    end
    # rubocop:enable Lint/MissingSuper

    def fetch(editions_and_link_types)
      edition_id_tuples = []
      content_id_tuples = []
      link_types_map = {}

      editions_and_link_types.each do |edition, link_type|
        edition_id_tuples.push("(#{edition.id},'#{link_type}')")
        content_id_tuples.push("('#{edition.content_id}','#{link_type}')")
        link_types_map[[edition.content_id, link_type]] = []
      end

      edition_links = Link
        .joins(:edition, { target_documents: @content_store })
        .includes(:edition, { target_documents: @content_store })
        .where(
          '("editions"."id", "links"."link_type") IN (?)',
          Arel.sql(edition_id_tuples.join(",")),
        )
        .where(target_documents: { locale: "en" })
        .order(link_type: :asc, position: :asc)

      link_set_links = Link
        .joins(:link_set, { target_documents: @content_store })
        .includes(:link_set, { target_documents: @content_store })
        .where(
          '("link_sets"."content_id", "links"."link_type") IN (?)',
          Arel.sql(content_id_tuples.join(",")),
        )
        .where(target_documents: { locale: "en" })
        .order(link_type: :asc, position: :asc)

      all_links = edition_links + link_set_links

      all_links.each_with_object(link_types_map) { |link, hash|
        hash[[(link.link_set || link.edition).content_id, link.link_type]].concat(editions_for_link(link))
      }.values
    end

  private

    def editions_for_link(link)
      link.target_documents.map { |document| document.send(@content_store) }
    end
  end
end
