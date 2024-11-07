module Presenters
  module ContentEmbed
    class BasePresenter
      include ActionView::Helpers::TagHelper

      def initialize(edition)
        @edition = edition
      end

      def render
        base_tag(content:)
      end

    private

      def content
        edition.title
      end

      def base_tag(content:, tag_type: :span)
        content_tag(
          tag_type,
          content,
          class: %W[content-embed content-embed__#{edition.document_type}],
        )
      end

      attr_reader :edition, :content_type
    end
  end
end
