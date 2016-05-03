module Presenters
  module Queries
    class ExpandLink
      attr_reader :item, :type, :visited

      def initialize(item, type, visited, set:)
        @item = item
        @type = type
        @visited = visited
        @set = set
      end

      def expand_link
        expanded = rules.expansion_fields(type).each_with_object({}) do |field, subhash|
          subhash[field] = item.public_send(field)
        end
        expanded.merge(expanded_links: expanded_links)
      end

    private

      def expanded_links
        return {} if invalid?
        { type => recursive_links }
      end

      def invalid?
        visited.include?(item.content_id) ||
          recursive_target_content_ids.empty? ||
          recursive_links.empty?
      end

      def recursive_links
        @recurseive_links ||= @set.expand_links(
          recursive_target_content_ids, type, visited << item.content_id
        )
      end

      def recursive_target_content_ids
        @recursive_target_content_ids ||= links.select { |link| recurse?(link.link_type) }.map(&:target_content_id)
      end

      def links
        @links ||= link_set.links.where(link_type: type)
      end

      def link_set
        LinkSet.find_by(content_id: item.content_id) || OpenStruct.new(links: Link.none)
      end

      def recurse?(type)
        rules.recurse?(type.to_sym)
      end

      def rules
        ::Queries::ExpansionRules
      end
    end
  end
end
