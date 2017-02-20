require "govspeak"

module Presenters
  class DetailsPresenter
    attr_reader :content_item_details, :change_history_presenter

    def initialize(content_item_details, change_history_presenter)
      @content_item_details = SymbolizeJSON.symbolize(content_item_details)
      @change_history_presenter = change_history_presenter
    end

    def details
      @_details ||=
        begin
          updated = recursively_transform_govspeak(content_item_details)
          updated[:change_history] = change_history unless change_history.blank?
          updated
        end
    end

  private

    def govspeak?(value)
      value.all? { |hsh| hsh.is_a?(Hash) } &&
        value.one? { |hsh| hsh[:content_type] == "text/govspeak" } &&
        value.none? { |hsh| hsh[:content_type] == "text/html" }
    end

    def process(value)
      return unless value
      wrapped_array = Array.wrap(value)
      return render_govspeak(value) if govspeak?(wrapped_array)
      return value if value.is_a?(String)
      return value if value.respond_to?(:has_key?) && value.has_key?(:content)
      value.map {|o| recursively_transform_govspeak(o) }
    end

    def recursively_transform_govspeak(obj)
      Array(obj).each_with_object({}) do |(key, value), memo|
        memo[key] = process(value)
      end
    end

    def change_history
      @_change_history ||= change_history_presenter.change_history
    end

    def render_govspeak(value)
      wrapped_value = Array.wrap(value)
      govspeak = {
        content_type: "text/html",
        content: rendered_govspeak(wrapped_value),
      }
      wrapped_value + [govspeak]
    end

    def rendered_govspeak(value)
      Govspeak::Document.new(raw_govspeak(value), govspeak_attributes).to_html
    end

    def raw_govspeak(value)
      value.find { |format| format[:content_type] == "text/govspeak" }[:content]
    end

    def govspeak_attributes
      {
        attachments: content_item_details[:attachments],
      }
    end
  end
end
