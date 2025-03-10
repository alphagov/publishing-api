module Sources
  class ReverseLinkedToEditionsSource < GraphQL::Dataloader::Source
    # rubocop:disable Lint/MissingSuper
    def initialize(content_store:)
      @content_store = content_store.to_sym
    end
    # rubocop:enable Lint/MissingSuper

    def fetch(editions_and_link_types)
      content_id_tuples = []
      link_types_map = {}

      editions_and_link_types.each do |edition, link_type|
        content_id_tuples.push("('#{edition.content_id}','#{link_type}')")
        link_types_map[[edition.content_id, link_type]] = []
      end

      all_links = Link
        .where(
          '("links"."target_content_id", "links"."link_type") IN (?)',
          Arel.sql(content_id_tuples.join(",")),
        )
        .includes(source_documents: @content_store)

      all_links.each_with_object(link_types_map) { |link, hash|
        if link.link_set
          hash[[link.target_content_id, link.link_type]].concat(editions_for_link_set_link(link))
        elsif link.edition
          hash[[link.target_content_id, link.link_type]] << link.edition
        end
      }.values
    end

  private

    def editions_for_link_set_link(link)
      link.source_documents.map { |document| document.send(@content_store) }
    end
  end
end
