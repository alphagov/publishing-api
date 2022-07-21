module Presenters
  module Queries
    class ExpandedLinkSet
      attr_reader :draft

      def self.by_edition(edition, with_drafts: false)
        new(edition: edition, with_drafts: with_drafts)
      end

      def self.by_content_id(content_id, locale: Edition::DEFAULT_LOCALE, with_drafts: false)
        new(content_id: content_id, locale: locale, with_drafts: with_drafts)
      end

      def initialize(options)
        @options = options
        @with_drafts = options.fetch(:with_drafts)
      end

      def links
        @links ||= expanded_links.merge(translations)
      end

    private

      attr_reader :options, :with_drafts

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
        present_expanded_links(link_expansion.links_with_content)
      end

      def present_expanded_links(links)
        links.transform_values do |link_hashes|
          link_hashes.map { |link_hash| present_expanded_link(link_hash) }
        end
      end

      def present_expanded_link(link_hash)
        link_hash.tap do |hash|
          if hash[:links]
            hash[:links] = present_expanded_links(hash[:links])
          end

          if hash[:details]
            hash[:details] = Presenters::DetailsPresenter.new(hash[:details], nil).details
          end
        end
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
