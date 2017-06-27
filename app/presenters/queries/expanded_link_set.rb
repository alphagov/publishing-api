module Presenters
  module Queries
    class ExpandedLinkSet
      attr_reader :draft

      def self.by_edition(edition, with_drafts: false)
        self.new(edition: edition, with_drafts: with_drafts)
      end

      def self.by_content_id(content_id, locale: Edition::DEFAULT_LOCALE, with_drafts: false)
        self.new(content_id: content_id, locale: locale, with_drafts: with_drafts)
      end

      def initialize(options)
        @options = options
        @with_drafts = options.fetch(:with_drafts)
      end

      def links
        @links ||= Rails.cache.fetch(cache_key, expires_in: 1.hour) do
          expanded_links.merge(translations)
        end
      end

    private

      attr_reader :options, :with_drafts

      def cache_key
        ["expanded-link-set", content_id, locale, with_drafts]
      end

      def edition
        @edition ||= options[:edition]
      end

      def content_id
        edition ? edition.content_id : options.fetch(:content_id)
      end

      def locale
        edition ? edition.locale : options.fetch(:locale)
      end

      def link_expansion
        if edition
          LinkExpansion.by_edition(edition, with_drafts: with_drafts)
        else
          LinkExpansion.by_content_id(content_id, locale: locale, with_drafts: with_drafts)
        end
      end

      def expanded_links
        link_expansion.links_with_content
      end

      def available_translations
        if edition
          AvailableTranslations.by_edition(edition, with_drafts: with_drafts)
        else
          AvailableTranslations.by_content_id(content_id, with_drafts: with_drafts)
        end
      end

      def translations
        available_translations.translations
      end
    end
  end
end
