module Presenters
  module Queries
    class ExpandedLinkSet
      attr_reader :draft

      def initialize(content_id:, draft:, locale_fallback_order: Edition::DEFAULT_LOCALE, edition_id:)
        @content_id = content_id
        @draft = draft
        @locale_fallback_order = Array(locale_fallback_order).freeze
        @edition_id = edition_id
      end

      def links
        @links ||= expanded_links.merge(translations)
      end

    private

      attr_reader :locale_fallback_order, :content_id, :edition_id

      def expanded_links
        LinkExpansion.new(content_id,
          with_drafts: draft,
          locale_fallback_order: locale_fallback_order,
        ).links_with_content
      end

      def translations
        AvailableTranslations.new(content_id, with_drafts: draft).translations
      end
    end
  end
end
