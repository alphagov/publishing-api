module Presenters
  module Queries
    class AvailableTranslations
      def initialize(content_id, with_drafts: false)
        @content_id = content_id
        @with_drafts = with_drafts
      end

      def translations
        if expanded_translations.present?
          { available_translations: expanded_translations }
        else
          {}
        end
      end

    private

      attr_reader :content_id, :with_drafts, :expanded_translations

      def grouped_translations
        Edition.with_document
          .where('documents.content_id': content_id, state: state_fallback_order)
          .pluck(:id, 'documents.locale', :state)
          .sort_by { |(_, _, state)| state_fallback_order.index(state.to_sym) }
          .group_by { |(_, locale)| locale }
      end

      def expand_translation(id)
        expansion_rules = LinkExpansion::Rules
        web_item = Edition.find_by(id: id)
        web_item.to_h.select { |f| expansion_rules.expansion_fields(:available_translations).include?(f) }
      end

      def expanded_translations
        @expanded_translations ||= grouped_translations.map { |_, (id)| expand_translation(id) }
      end

      def state_fallback_order
        with_drafts ? %i[draft published] : %i[published]
      end
    end
  end
end
