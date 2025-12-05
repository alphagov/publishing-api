module Presenters
  class DetailsPresenter
    attr_reader :content_item_details, :change_history_presenter, :content_embed_presenter, :locale

    def initialize(content_item_details, change_history_presenter, content_embed_presenter, locale: nil)
      @content_item_details = SymbolizeJSON.symbolize(content_item_details)
      @change_history_presenter = change_history_presenter
      @content_embed_presenter = content_embed_presenter
      @locale = locale
    end

    def details
      updated = content_embed(content_item_details).presence || content_item_details
      updated[:change_history] = change_history if change_history.present?
      updated
    end

  private

    def content_embed(content_item_details)
      @content_embed ||= content_embed_presenter&.render_embedded_content(content_item_details)
    end

    def change_history
      @change_history ||= change_history_presenter&.change_history
    end
  end
end
