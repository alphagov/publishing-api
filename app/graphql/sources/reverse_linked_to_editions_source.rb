module Sources
  class ReverseLinkedToEditionsSource < GraphQL::Dataloader::Source
    # rubocop:disable Lint/MissingSuper
    def initialize(parent_object:)
      @object = parent_object
      @content_store = parent_object.content_store.to_sym
    end
    # rubocop:enable Lint/MissingSuper

    def fetch(link_types)
      all_links = @object
        .document
        .reverse_links
        .includes(source_documents: @content_store)
        .where(link_type: link_types)

      link_types_map = link_types.index_with { [] }

      all_links.each_with_object(link_types_map) { |link, hash|
        hash[link.link_type].concat(editions_for_link(link))
      }.values
    end

  private

    def editions_for_link(link)
      link.source_documents.map { |document| document.send(@content_store) }
    end
  end
end
