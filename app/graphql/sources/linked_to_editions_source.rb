module Sources
  class LinkedToEditionsSource < GraphQL::Dataloader::Source
    # rubocop:disable Lint/MissingSuper
    def initialize(parent_object:)
      @object = parent_object
      @content_store = parent_object.content_store.to_sym
    end
    # rubocop:enable Lint/MissingSuper

    def fetch(link_types)
      all_links = @object.document.link_set_links
        .includes(target_documents: @content_store) # content_store is :live or :draft (a Document has_one Edition by that name)
        .where(link_type: link_types)
        .where(target_documents: { locale: "en" })

      link_types_map = link_types.index_with { [] }

      all_links.each_with_object(link_types_map) { |link, hash|
        hash[link.link_type].concat(editions_for_link(link))
      }.values
    end

  private

    def editions_for_link(link)
      link.target_documents.map { |document| document.send(@content_store) }
    end
  end
end
