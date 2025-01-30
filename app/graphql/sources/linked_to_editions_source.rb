module Sources
  class LinkedToEditionsSource < GraphQL::Dataloader::Source
    # rubocop:disable Lint/MissingSuper
    def initialize(content_store:)
      @content_store = content_store.to_sym
    end
    # rubocop:enable Lint/MissingSuper

    def fetch(editions_and_link_types)
      content_id_tuples = editions_and_link_types.map { |edition, link_type| "('#{edition.content_id}','#{link_type}')" }.join(",")
      edition_id_tuples = editions_and_link_types.map { |edition, link_type| "(#{edition.id},'#{link_type}')" }.join(",")

      edition_links = Link
        .joins(:edition, { target_documents: @content_store })
        .includes(:edition, { target_documents: @content_store })
        .where('("editions"."id", "links"."link_type") IN (?)', Arel.sql(edition_id_tuples))
        .where(target_documents: { locale: "en" })
        .order(link_type: :asc, position: :asc)

      link_set_links = Link
        .joins(:link_set, { target_documents: @content_store })
        .includes(:link_set, { target_documents: @content_store })
        .where('("link_sets"."content_id", "links"."link_type") IN (?)', Arel.sql(content_id_tuples))
        .where(target_documents: { locale: "en" })
        .order(link_type: :asc, position: :asc)

      all_links = edition_links + link_set_links

      link_types_map = editions_and_link_types.map { [_1.content_id, _2] }.index_with { [] }

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
