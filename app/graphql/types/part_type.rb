# frozen_string_literal: true

module Types
  class PartType < Types::BaseObject
    description "A part"
    field :title, String
    field :body_html, String
    field :body_govspeak, String
    field :slug, String

    # TODO duplicated from generic_details_type
    def body_html
      html = object.fetch("body", [])
                   .filter { |item| item["content_type"] == "text/html" }
                   .map { |item| item["content"] }.first
      return html if html.present?

      govspeak = body_govspeak
      return Govspeak::Document.new(govspeak).to_html if govspeak.present?

      # If we couldn't find any govspeak or HTML
      nil
    end

    # TODO duplicated from generic_details_type
    def body_govspeak
      object.fetch("body", [])
            .filter { _1["content_type"] == "text/govspeak" }
            .map { _1["content"] }
            .first
    end
  end
end
