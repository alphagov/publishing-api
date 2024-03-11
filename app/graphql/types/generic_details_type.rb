# frozen_string_literal: true

module Types
  class GenericDetailsType < Types::BaseObject
    description "Edition details - fields can vary depending on the schema. Specific schemas should have more specific details types."
    field :keys, [String]
    field :dig, String do
      argument :path, [String]
    end
    field :body_html, String
    field :body_govspeak, String

    # TODO This is here mostly as a debugging aid - it should probably be removed before production
    def keys
      object.keys
    end

    # TODO This is here mostly as a debugging aid - it should probably be removed before production
    def dig(path: [])
      return object.to_json if path.empty?

      path_with_numbers = path.map do |segment|
        segment =~ /\A\d+\Z/ ? segment.to_i : segment
      end
      result = object.dig(*path_with_numbers)
      result.is_a?(Hash) || result.is_a?(Array) ? result.to_json : result
    end

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

    def body_govspeak
      object.fetch("body", [])
            .filter { _1["content_type"] == "text/govspeak" }
            .map { _1["content"] }
            .first
    end
  end
end
