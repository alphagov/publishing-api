module Presenters
  module Queries
    class ExpandedLinkSet
      def initialize(link_set:, fallback_order:, visited_link_sets: [], recursing_type: nil)
        @link_set = link_set
        @fallback_order = Array(fallback_order)
        @visited_link_sets = visited_link_sets
        @recursing_type = recursing_type
      end

      def links
        if top_level?
          dependees.merge(dependents)
        else
          dependees
        end
      end

    private

      attr_reader :fallback_order, :link_set, :visited_link_sets, :recursing_type

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
            expanded_links: next_level,
          )
        end
      end

      def recurse_if_not_visited(type, next_link_set, visited_link_sets)
        return {} if visited_link_sets.include?(next_link_set)

        self.class.new(
          link_set: next_link_set,
          fallback_order: fallback_order,
          visited_link_sets: (visited_link_sets << link_set),
          recursing_type: type,
        ).links
      end

      def expanding_this_type?(type)
        return true if recursing_type.nil?
        recursing_type == type
      end

      def dependees
        link_set.links.group_by(&:link_type).each_with_object({}) do |(type, links), hash|
          links = links.map(&:target_content_id)
          expansion_rules = ::Queries::DependeeExpansionRules

          expanded_links = expand_links(links, type.to_sym, expansion_rules)

          hash[type.to_sym] = expanded_links if expanded_links.any?
        end
      end

      def dependents
        Link.where(target_content_id: link_set.content_id).group_by(&:link_type).each_with_object({}) do |(type, links), hash|
          inverted_type_name = ::Queries::DependentExpansionRules.reverse_name_for(type)
          next unless inverted_type_name

          links = links.map { |l| l.link_set.content_id }
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
        @content_item ||= {}

        fallback_order.each do |state|
          @content_item[target_content_id] ||=
            content_item_for_state(state, target_content_id)
        end

        @content_item[target_content_id]
      end

      def content_item_for_state(state, content_id)
        State.filter(ContentItem.all, name: state).find_by(content_id: content_id)
      end
    end
  end
end
