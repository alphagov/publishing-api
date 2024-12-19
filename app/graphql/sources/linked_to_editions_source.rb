module Sources
  class LinkedToEditionsSource < GraphQL::Dataloader::Source
    def initialize(parent_object:)
      @object = parent_object
      @content_store = parent_object.content_store.to_sym
    end

    def fetch(link_types)
      all_links = @object.document.link_set_links
        .includes(
          # content_store is :live or :draft
          # (a Document has_one Edition by that name)
          target_documents: @content_store
        )
        .where(link_type: link_types)
        .where(target_documents: { locale: "en" })

      link_types_map = link_types.each_with_object({}) do |link_type, hash|
        hash[link_type] = []
      end

      all_links.each_with_object(link_types_map) { |link, hash|
        hash[link.link_type].concat(
          link.target_documents.map { |document|
            document.send(@content_store)
          }
        )
      }.values
    end
  end
end
