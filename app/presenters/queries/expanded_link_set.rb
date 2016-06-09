module Presenters
  module Queries
    class ExpandedLinkSet
      def initialize(link_set:, state_fallback_order:, locale_fallback_order: ContentItem::DEFAULT_LOCALE, visited_link_sets: [], recursing_type: nil)
        @link_set = link_set
        @state_fallback_order = Array(state_fallback_order)
        @locale_fallback_order = Array(locale_fallback_order)
        @visited_link_sets = visited_link_sets
        @recursing_type = recursing_type
      end

      def links
        if top_level?
          dependees.merge(dependents).merge(translations)
        else
          dependees
        end
      end

    private

      attr_reader :state_fallback_order, :locale_fallback_order, :link_set, :visited_link_sets, :recursing_type

      def top_level?
        visited_link_sets.empty?
      end

      def expand_links(target_content_ids, type, rules)
        return {} unless expanding_this_type?(type)

        content_items = valid_web_content_items(target_content_ids)

        content_items.map do |item|
          expanded_links = ExpandLink.new(item, type, rules).expand_link

          if ::Queries::DependentExpansionRules.recurse?(type)
            next_link_set = LinkSet.find_by(content_id: item.content_id) || OpenStruct.new(links: [])
            next_level = recurse_if_not_visited(type, next_link_set, visited_link_sets)
          else
            next_level = {}
          end

          expanded_links.merge(
            links: next_level,
          )
        end
      end

      def recurse_if_not_visited(type, next_link_set, visited_link_sets)
        return {} if visited_link_sets.include?(next_link_set)

        self.class.new(
          link_set: next_link_set,
          state_fallback_order: state_fallback_order,
          locale_fallback_order: locale_fallback_order,
          visited_link_sets: (visited_link_sets << link_set),
          recursing_type: type,
        ).links
      end

      def expanding_this_type?(type)
        return true if recursing_type.nil?
        recursing_type == type
      end

      def dependees
        return {} unless link_set.is_a? LinkSet
        grouped_links = link_set.links
          .pluck(:link_type, :target_content_id, :passthrough_hash)
          .group_by(&:first)

        grouped_links.each_with_object({}) do |(type, links), hash|
          links = links.map { |l| l[2] || l[1] }
          expansion_rules = ::Queries::DependeeExpansionRules

          expanded_links = expand_links(links, type.to_sym, expansion_rules)

          hash[type.to_sym] = expanded_links if expanded_links.any?
        end
      end

      def dependents
        grouped_links = Link
          .where(target_content_id: link_set.content_id)
          .joins(:link_set)
          .pluck(:link_type, :content_id).group_by(&:first)

        grouped_links.each_with_object({}) do |(type, links), hash|
          inverted_type_name = ::Queries::DependentExpansionRules.reverse_name_for(type)
          next unless inverted_type_name

          links = links.map(&:last)
          expansion_rules = ::Queries::DependentExpansionRules

          expanded_links = expand_links(links, type.to_sym, expansion_rules)

          hash[inverted_type_name.to_sym] = expanded_links if expanded_links.any?
        end
      end

      def valid_web_content_items(target_content_ids)
        target_content_ids = without_passsthrough_hashes(target_content_ids)
        web_content_items(target_content_ids).select(&:content_item)
      end

      def without_passsthrough_hashes(target_content_ids)
        target_content_ids.reject { |content_id| content_id.is_a?(Hash) }
      end

      def web_content_items(target_content_ids)
        target_content_ids.map do |target_content_id|
          web_content_item(target_content_id)
        end
      end

      def web_content_item(target_content_id)
        @web_content_item ||= {}
        @web_content_item[target_content_id] ||=
          ::WebContentItem.new(content_item(target_content_id))
      end

      def content_item(target_content_id)
        content_item_filter = ContentItemFilter.new(
          scope: ContentItem.where(content_id: target_content_id)
        )

        @content_item ||= {}

        locale_fallback_order.each do |locale|
          state_fallback_order.each do |state|
            @content_item[target_content_id] ||=
              content_item_filter.filter(state: state, locale: locale).first
          end
        end

        @content_item[target_content_id]
      end

      def translations
        AvailableTranslations.new(link_set.content_id, state_fallback_order).translations
      end
    end
  end
end
