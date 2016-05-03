module Presenters
  module Queries
    class ExpandedLinkSet
      def initialize(link_set:, fallback_order:)
        @link_set = link_set
        @fallback_order = Array(fallback_order)
      end

      def links
        link_set.links.group_by(&:link_type).each_with_object({}) do |(type, links), hash|
          hash[type.to_sym] = expand_links(links.map(&:target_content_id), type.to_sym)
        end
      end

      def expand_links(target_content_ids, type, visited = [link_set.content_id])
        valid_web_content_items(target_content_ids).map do |item|
          ExpandLink.new(item, type, visited, set: self).expand_link
        end
      end

    private

      attr_reader :fallback_order, :link_set

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
