require "govspeak"

module Presenters
  class DetailsPresenter
    attr_reader :content_item_details

    def initialize(content_item_details)
      @content_item_details = SymbolizeJSON.symbolize(content_item_details)
    end

    def details
      @_details ||=
        begin
          content_item_details.each_with_object({}) do |(key, val), seed|
            seed[key] = append_transformed_govspeak(val)
          end
        end
    end

  private

    def append_transformed_govspeak(value)
      wrapped_value = Array.wrap(value)
      return value unless requires_govspeak_html_transform?(wrapped_value)
      govspeak = {
        content_type: "text/html",
        content: rendered_govspeak(wrapped_value),
      }
      wrapped_value + [govspeak]
    end

    def raw_govspeak(value)
      value.find { |format| format[:content_type] == "text/govspeak" }[:content]
    end

    def requires_govspeak_html_transform?(value)
      value.all? { |hsh| hsh.is_a?(Hash) } &&
        value.one? { |hsh| hsh[:content_type] == "text/govspeak" } &&
        value.none? { |hsh| hsh[:content_type] == "text/html" }
    end

    def rendered_govspeak(value)
      Govspeak::Document.new(raw_govspeak(value), govspeak_attributes).to_html
    end

    def govspeak_attributes
      {
        attachments: content_item_details[:attachments],
      }
    end
  end
end
