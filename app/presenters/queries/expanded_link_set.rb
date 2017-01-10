module Presenters
  module Queries
    class ExpandedLinkSet
      attr_reader :state_fallback_order

      def initialize(content_id:, state_fallback_order:, locale_fallback_order: Edition::DEFAULT_LOCALE)
        @content_id = content_id
        @state_fallback_order = Array(state_fallback_order.freeze)
        @locale_fallback_order = Array(locale_fallback_order.freeze)
      end

      def links
        @links ||= dependees.merge(dependents).merge(translations)
      end

      def web_content_items(target_content_ids)
        return [] unless target_content_ids.present?
        ::Queries::GetWebEditions.(
          ::Queries::GetEditionIdsWithFallbacks.(
            target_content_ids,
            locale_fallback_order: locale_fallback_order,
            state_fallback_order: state_fallback_order + [:withdrawn]
          )
        )
      end

    private

      attr_reader :locale_fallback_order, :content_id

      def dependees
        ExpandDependees.new(content_id, self).expand
      end

      def dependents
        ExpandDependents.new(content_id, self).expand
      end

      def translations
        AvailableTranslations.new(content_id, state_fallback_order).translations
      end
    end
  end
end
