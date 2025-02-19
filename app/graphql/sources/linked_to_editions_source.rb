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
        .joins(edition: :document)
        .where('("editions"."id", "links"."link_type") IN (?)', Arel.sql(edition_id_tuples))
        .order(link_type: :asc, position: :asc)
        .select("link_type", "position", "target_content_id", "editions.id", "documents.content_id")

      link_set_links = Link
        .joins(:link_set)
        .where('("link_sets"."content_id", "links"."link_type") IN (?)', Arel.sql(content_id_tuples))
        .order(link_type: :asc, position: :asc)
        .select("link_type", "position", "target_content_id", "link_sets.content_id")

      all_links = edition_links + link_set_links

      editions = Edition
        .joins(:document)
        .where(
          document: {
            locale: "en",
            content_id: all_links.map(&:target_content_id),
          },
          content_store: @content_store,
        )
        .select(
          "id",
          "title",
          "base_path",
          "details",
          "content_store",
          "document.content_id",
        )

      editions_map = editions.each_with_object({}) do |e, hash|
        hash[e.content_id] = e
      end
      link_types_map = editions_and_link_types.map { [_1.content_id, _2] }.index_with { [] }

      all_links.each_with_object(link_types_map) { |link, hash|
        unless editions_map[link.target_content_id].nil?
          hash[[link.content_id, link.link_type]] << editions_map[link.target_content_id]
        end
      }.values
    end
  end
end
