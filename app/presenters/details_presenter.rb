require "govspeak"

module Presenters
  class DetailsPresenter
    attr_reader :content_item_details
    delegate :can_render_govspeak?, :raw_govspeak, to: :body_presenter

    def initialize(content_item_details)
      @content_item_details = SymbolizeJSON.symbolize(content_item_details)
    end

    def details
      @details ||= presented_details
    end

  private

    def body_presenter
      @_body_presenter ||=
        begin
          body = content_item_details[:body]
          if body.is_a?(String)
            SimpleContentPresenter.new(body)
          else
            TypedContentPresenter.new(body)
          end
        end
    end

    def presented_details
      return content_item_details unless can_render_govspeak?
      govspeak = { content_type: "text/html", content: rendered_govspeak }
      content_item_details.merge(body: body_presenter.body + [govspeak])
    end

    def rendered_govspeak
      Govspeak::Document.new(raw_govspeak).to_html
    end

    class SimpleContentPresenter
      attr_reader :body

      def initialize(body)
        @body = body
      end

      def can_render_govspeak?; false; end

      def raw_govspeak; nil; end
    end

    class TypedContentPresenter
      attr_reader :body

      def initialize(body)
        @body = Array.wrap(body)
      end

      def can_render_govspeak?
        has_html = body.any? { |format| format[:content_type] == "text/html" }
        raw_govspeak.present? && !has_html
      end

      def raw_govspeak
        if (govspeak = body.find { |format| format[:content_type] == "text/govspeak" })
          govspeak[:content]
        end
      end
    end
  end
end
