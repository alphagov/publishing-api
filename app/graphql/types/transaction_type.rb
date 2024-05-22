module Types
  class TransactionType < Types::EditionType
    field :introductory_paragraph, String
    field :more_information, String
    field :start_button_text, String
    field :transaction_start_link, String
    field :related_links, [EditionType]

    def introductory_paragraph
      content_html(:introductory_paragraph)
    end

    def more_information
      content_html(:more_information)
    end

    def start_button_text
      object.details[:start_button_text]
    end

    def transaction_start_link
      object.details[:transaction_start_link]
    end

    def related_links
      content_ids = dataloader.with(Sources::LinkSetLinksFromSource, %i[ordered_related_items])
                              .load(object.content_id)
                              .flat_map { |link| link.target_content_id }
      dataloader.with(Sources::EditionSource).load_all(content_ids)
    end

    private

    def content_html(key)
      html = object.details.fetch(key, [])
                   .filter { |item| item[:content_type] == "text/html" }
                   .map { |item| item[:content] }.first
      return html if html.present?

      govspeak = content_govspeak(key)
      return Govspeak::Document.new(govspeak).to_html if govspeak.present?

      # If we couldn't find any govspeak or HTML
      nil
    end

    def content_govspeak(key)
      object.details.fetch(key, [])
            .filter { _1[:content_type] == "text/govspeak" }
            .map { _1[:content] }
            .first
    end
  end
end