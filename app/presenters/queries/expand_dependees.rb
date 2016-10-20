module Presenters
  module Queries
    class ExpandDependees
      def initialize(content_id, controller)
        @content_id = content_id
        @controller = controller
      end

      def expand
        parents(content_id)
      end

    private

      attr_reader :content_id, :controller

      def parents(content_id, type = nil, visited = [], level_index = 0)
        visited << content_id
        links = all_links(content_id, type)
        cached_web_content_items = all_web_content_items(links)
        level = links.each_with_object({}) do |link, memo|
          link_type = link["link_type"].to_sym
          memo[link_type] = expand_level(link, cached_web_content_items, visited, level_index).compact
        end
        level.select { |_k, v| v.present? }
      end

      def all_web_content_items(links)
        uniq_links = links.flat_map { |l| JSON.parse(l["target_content_ids"]) }.uniq
        controller.web_content_items(uniq_links).each_with_object({}) { |w, memo| memo[w.content_id] = w }
      end

      def expand_level(link, all_web_content_items, visited, level_index)
        JSON.parse(link["target_content_ids"]).map do |target_id|
          rules.expand_field(all_web_content_items[target_id]).tap do |expanded|
            next_level = next_level(link, target_id, visited, level_index)
            expanded.merge!(links: next_level) if expanded
          end
        end
      end

      def next_level(current_level, target_id, visited, level_index)
        return {} if visited.include?(target_id)
        link_type = current_level["link_type"]
        return {} unless rules.recurse?(current_level["link_type"], level_index)
        level_index += 1
        visited << target_id
        next_level_type = rules.next_level(current_level["link_type"], level_index)
        parents(target_id, next_level_type, visited.uniq, level_index)
      end

      def all_links(content_id, link_type = nil)
        sql = <<-SQL
          select links.link_type,
            json_agg(links.target_content_id order by links.link_type asc, links.position asc) as target_content_ids
          from links
          join link_sets on link_sets.id = links.link_set_id
          where link_sets.content_id = '#{content_id}'
          #{"and link_type = '#{link_type}'" if link_type}
          group by links.link_type;
        SQL
        ActiveRecord::Base.connection.execute(sql)
      end

      def rules
        ::Queries::DependeeExpansionRules
      end

    end
  end
end
