module Presenters
  module Queries
    class ExpandedLinkSet
      def initialize(content_id:, state_fallback_order:, locale_fallback_order: ContentItem::DEFAULT_LOCALE, visited_content_ids: [], recursing_type: nil)
        @content_id = content_id
        @state_fallback_order = Array(state_fallback_order)
        @locale_fallback_order = Array(locale_fallback_order)
        @visited_content_ids = visited_content_ids
        @recursing_type = recursing_type
      end

      def links
        if top_level?
          @links ||= dependees.merge(dependents).merge(translations)
        else
          @links ||= dependees
        end
      end

    private

      attr_reader :state_fallback_order, :locale_fallback_order, :content_id, :visited_content_ids, :recursing_type

      def top_level?
        visited_content_ids.empty?
      end

      def expand_links(target_content_ids, type, rules)
        return {} unless expanding_this_type?(type)

        content_items = web_content_items(target_content_ids)

        content_items.map do |item|
          expanded_links = ExpandLink.new(item, item.document_type.to_sym, rules).expand_link

          if ::Queries::DependentExpansionRules.recurse?(type)
            next_level = recurse_if_not_visited(type, item.content_id, visited_content_ids)
          else
            next_level = {}
          end

          expanded_links.tap do |el|
            el[:links] = next_level unless expanded_links.empty?
          end
        end
      end

      def recurse_if_not_visited(type, next_content_id, visited_content_ids)
        return {} if visited_content_ids.include?(next_content_id)

        self.class.new(
          content_id: next_content_id,
          state_fallback_order: state_fallback_order,
          locale_fallback_order: locale_fallback_order,
          visited_content_ids: (visited_content_ids << content_id),
          recursing_type: type,
        ).links
      end

      def expanding_this_type?(type)
        return true if recursing_type.nil?
        recursing_type == type
      end

      def dependees
        grouped_links = LinkSet
          .eager_load(:links)
          .where(content_id: content_id)
          .pluck(:link_type, :target_content_id)
          .group_by(&:first)

        return {} if grouped_links.keys.compact.empty?

        grouped_links.each_with_object({}) do |(type, links), hash|
          links = links.map { |l| l[2] || l[1] }
          expansion_rules = ::Queries::DependeeExpansionRules

          expanded_links = expand_links(links, type.to_sym, expansion_rules)

          hash[type.to_sym] = expanded_links.reject(&:empty?) if expanded_links.any?
        end
      end

      def dependents
        grouped_links = Link
          .where(target_content_id: content_id)
          .joins(:link_set)
          .pluck(:link_type, :content_id).group_by(&:first)

        grouped_links.each_with_object({}) do |(type, links), hash|
          inverted_type_name = ::Queries::DependentExpansionRules.reverse_name_for(type)
          next unless inverted_type_name

          links = links.map(&:last)
          expansion_rules = ::Queries::DependentExpansionRules

          expanded_links = expand_links(links, type.to_sym, expansion_rules)

          hash[inverted_type_name.to_sym] = expanded_links.reject(&:empty?) if expanded_links.any?
        end
      end

      def web_content_items(target_content_ids)
        ::Queries::GetWebContentItems.(
          ::Queries::GetContentItemIdsWithFallbacks.(
            target_content_ids,
            locale_fallback_order: locale_fallback_order,
            state_fallback_order: state_fallback_order
          )
        )
      end

      def translations
        AvailableTranslations.new(content_id, state_fallback_order).translations
      end
    end
  end
end
