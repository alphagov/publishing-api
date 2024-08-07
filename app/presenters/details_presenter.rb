require "govspeak"

module Presenters
  class DetailsPresenter
    attr_reader :content_item_details, :change_history_presenter, :content_embed_presenter

    def initialize(content_item_details, change_history_presenter, content_embed_presenter)
      @content_item_details = SymbolizeJSON.symbolize(content_item_details)
      @change_history_presenter = change_history_presenter
      @content_embed_presenter = content_embed_presenter
    end

    def details
      @details ||=
        begin
          updated = content_embed(content_item_details).presence || content_item_details
          updated = recursively_transform_govspeak(updated)
          updated[:change_history] = change_history if change_history.present?
          updated
        end
    end

  private

    def govspeak_content?(value)
      wrapped = Array.wrap(value)
      wrapped.all? { |hsh| hsh.is_a?(Hash) } &&
        wrapped.one? { |hsh| hsh[:content_type] == "text/govspeak" } &&
        wrapped.none? { |hsh| hsh[:content_type] == "text/html" }
    end

    def html_content?(value)
      wrapped = Array.wrap(value)
      wrapped.all? { |hsh| hsh.is_a?(Hash) } &&
        wrapped.one? { |hsh| hsh[:content_type] == "text/html" }
    end

    def recursively_transform_govspeak(obj)
      return obj if !obj.respond_to?(:map) || html_content?(obj)
      return render_govspeak(obj) if govspeak_content?(obj)

      if obj.is_a?(Hash)
        obj.transform_values do |value|
          recursively_transform_govspeak(value)
        end
      else
        obj.map { |o| recursively_transform_govspeak(o) }
      end
    end

    def content_embed(content_item_details)
      @content_embed ||= content_embed_presenter&.render_embedded_content(content_item_details)
    end

    def change_history
      @change_history ||= change_history_presenter&.change_history
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
