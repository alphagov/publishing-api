module Presenters
  module Queries
    class AvailableTranslations
      def initialize(content_id, state_fallback_order)
        @content_id = content_id
        @state_fallback_order = state_fallback_order
      end

      def translations
        if expanded_translations.present?
          { available_translations: expanded_translations }
        else
          {}
        end
      end

    private

      attr_reader :content_id, :state_fallback_order, :expanded_translations

      def scope
        scope = ContentItem.where(content_id: content_id)
        scope = State.join_content_items(scope)
        scope = Translation.join_content_items(scope)
        scope.select(*%w(id locale name))
      end

      def filter_states
        scope.where("states.name" => state_fallback_order)
      end

      def grouped_translations
        filter_states
          .sort_by { |item| state_fallback_order.index(item.name.to_sym) }
          .group_by(&:locale)
      end

      def expand_translation(item)
        expansion_rules = ::Queries::DependentExpansionRules
        web_item = ::Queries::GetWebContentItems.call(item.id).first
        ExpandLink.new(web_item, :available_translations, expansion_rules).expand_link
      end

      def expanded_translations
        @expanded_translations ||= grouped_translations.map { |_, items| expand_translation(items.first) }
      end
    end
  end
end
