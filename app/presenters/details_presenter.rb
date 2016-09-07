require "govspeak"

module Presenters
  class DetailsPresenter
    attr_reader :content_item_details, :body

    def initialize(content_item_details)
      @content_item_details = SymbolizeJSON.symbolize(content_item_details)
      @body = content_item_details[:body]
    end

    def details
      @details ||= presented_details
    end

  private

    def presented_details
      return content_item_details unless can_render_govspeak?
      govspeak = { content_type: "text/html", content: rendered_govspeak }
      content_item_details.merge(body: body + [govspeak])
    end

    def can_render_govspeak?
      return false unless body.respond_to?(:any?)
      has_html = body.any? { |format| format[:content_type] == "text/html" }
      raw_govspeak.present? && !has_html
    end

    def raw_govspeak
      return nil unless body.respond_to?(:find)
      govspeak = body.find { |format| format[:content_type] == "text/govspeak" }
      govspeak ? govspeak[:content] : nil
    end

    def rendered_govspeak
      Govspeak::Document.new(raw_govspeak).to_html
    end
  end
end
