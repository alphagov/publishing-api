module Presenters
  module Queries
    class AvailableTranslations
      def self.by_edition(edition, with_drafts: false)
        self.new(edition: edition, with_drafts: with_drafts)
      end

      def self.by_content_id(content_id, with_drafts: false)
        self.new(content_id: content_id, with_drafts: with_drafts)
      end

      def initialize(options)
        @options = options
        @with_drafts = options.fetch(:with_drafts)
      end

      def translations
        return {} if expanded_translations.blank?

        { available_translations: expanded_translations }
      end

    private

      attr_reader :options, :with_drafts

      def edition
        @edition ||= options[:edition]
      end

      def content_id
        edition ? edition.content_id : options.fetch(:content_id)
      end

      def grouped_translations
        pluck_and_sort_editions(edition_scope)
      end

      def expand_translation(id)
        expansion_fields = ExpansionRules
          .expansion_fields(:available_translations)
        web_item(id).select { |field| expansion_fields.include?(field) }
      end

      def edition_for_id(id)
        return edition if edition && edition.id == id

        Edition.find_by(id: id)
      end

      def web_item(id)
        edition_for_id(id).to_h
      end

      def expanded_translations
        @expanded_translations ||= grouped_translations.map do |_, (id)|
          expand_translation(id)
        end
      end

      def state_fallback_order
        return %i[draft published unpublished] if with_drafts

        %i[published unpublished]
      end

      def edition_scope
        scope = Edition
          .with_document
          .with_unpublishing
          .where(
            documents: { content_id: content_id },
            state: state_fallback_order,
          )

        # filter out unpublishings which aren't withdrawals (i.e. gone, redirect, etc)
        scope
          .where("
            editions.state != 'unpublished' OR unpublishings.type = 'withdrawal'
          ")
      end

      def pluck_and_sort_editions(scope)
        scope.pluck(:id, :locale, :state)
          .sort_by { |(_, _, state)| state_fallback_order.index(state.to_sym) }
          .group_by { |(_, locale)| locale }
          .transform_values(&:first)
      end
    end
  end
end
