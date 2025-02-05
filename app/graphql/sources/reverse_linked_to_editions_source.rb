module Sources
  class ReverseLinkedToEditionsSource < GraphQL::Dataloader::Source
    # rubocop:disable Lint/MissingSuper
    def initialize(parent_object:, only_current: false)
      @object = parent_object
      @content_store = parent_object.content_store.to_sym
      @only_current = only_current
    end
    # rubocop:enable Lint/MissingSuper

    def fetch(link_types)
      all_links = if @only_current
                    query = <<~SQL
                      SELECT links.*
                      FROM links
                      LEFT JOIN link_sets ON links.link_set_id = link_sets.id
                      LEFT JOIN documents AS link_set_link_documents ON link_sets.content_id = link_set_link_documents.content_id
                      LEFT JOIN editions AS link_set_link_editions ON link_set_link_documents.id = link_set_link_editions.document_id
                      LEFT JOIN editions AS edition_link_editions ON links.edition_id = edition_link_editions.id
                      WHERE links.target_content_id = '#{@object.content_id}'
                      AND links.link_type IN (#{link_types.map { |type| "'#{type}'" }.join(',')})
                      AND (link_set_link_editions.content_store = '#{@content_store}' OR edition_link_editions.content_store = '#{@content_store}')
                      AND (link_set_link_editions.details ->> 'current' = 'true' OR edition_link_editions.details ->> 'current' = 'true')
                    SQL

                    Link.from("(#{query}) AS links")
                  else
                    Link
                      .where(target_content_id: @object.content_id, link_type: link_types)
                      .includes(source_documents: @content_store)
                  end

      link_types_map = link_types.index_with { [] }

      all_links.each_with_object(link_types_map) { |link, hash|
        if link.link_set
          hash[link.link_type].concat(editions_for_link_set_link(link))
        elsif link.edition
          hash[link.link_type] << link.edition
        end
      }.values
    end

  private

    def editions_for_link_set_link(link)
      link.source_documents.map { |document| document.send(@content_store) }
    end
  end
end
