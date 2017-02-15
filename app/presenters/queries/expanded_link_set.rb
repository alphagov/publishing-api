module Presenters
  module Queries
    class ExpandedLinkSet
      attr_reader :draft

      def initialize(content_id:, draft: false, locale: Edition::DEFAULT_LOCALE)
        @content_id = content_id
        @draft = draft
        @locale = locale
      end

      def links
        @links ||= expanded_links.merge(translations)
      end

    private

      attr_reader :content_id, :draft, :locale

      def expanded_links
        LinkExpansion.new(content_id,
          with_drafts: draft,
          locale: locale,
        ).links_with_content
      end

      def translations
        AvailableTranslations.new(content_id, with_drafts: draft).translations
      end
    end
  end
end
