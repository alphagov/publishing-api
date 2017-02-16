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

    def recursively_transform_govspeak(obj)
      if is_govspeak_renderable?(obj)
        ensure_govspeak_rendered(obj)
      elsif obj.is_a?(Hash)
        obj.each_with_object({}) do |(key, val), seed|
          seed[key] = recursively_transform_govspeak(val)
        end
      elsif obj.is_a?(Array)
        obj.map { |val| recursively_transform_govspeak(val) }
      else
        obj
      end
    end

    def change_history
      @_change_history ||= change_history_presenter.change_history
    end

    def ensure_govspeak_rendered(obj)
      if already_rendered?(obj)
        obj
      else
        render_govspeak(obj)
      end
    end

    def render_govspeak(value)
      wrapped_value = Array.wrap(value)
      govspeak = {
        content_type: "text/html",
        content: rendered_govspeak(wrapped_value),
      }
      wrapped_value + [govspeak]
    end

    def already_rendered?(obj)
      value = Array.wrap(obj)
      value.one? { |hsh| contains_rendered_html?(hsh) }
    end

    def is_govspeak_renderable?(obj)
      value = Array.wrap(obj)
      value.one? { |hsh| is_govspeak_content?(hsh) }
    end

    def is_govspeak_content?(hsh)
      hsh.is_a?(Hash) && hsh[:content_type] == "text/govspeak"
    end

    def contains_rendered_html?(hsh)
      hsh.is_a?(Hash) && hsh[:content_type] == "text/html"
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
