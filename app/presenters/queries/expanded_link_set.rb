module Presenters
  module Queries
    class ExpandedLinkSet
      def initialize(content_id:, state_fallback_order:, locale_fallback_order: ContentItem::DEFAULT_LOCALE)
        @content_id = content_id
        @state_fallback_order = Array(state_fallback_order)
        @locale_fallback_order = Array(locale_fallback_order)
      end

      def links
        @links ||= dependees.merge(dependents).merge(translations)
      end

    private

      attr_reader :state_fallback_order, :locale_fallback_order, :content_id

      def children(content_id, type = nil, visited = [], level_index = 0)
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
        web_content_items(uniq_links).each_with_object({}) { |w, memo| memo[w.content_id] = w }
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
        children(target_id, next_level_type, visited.uniq, level_index)
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

      def dependees
        children(content_id)
      end

      def parent
        @parent ||= web_content_items([content_id]).first
      end

      def expanded_parent
        @expanded_parent ||= parent.to_h.select { |k, _v| rules.expansion_fields(parent.document_type.to_sym).include?(k) }.merge(links: {})
      end

      def dependents
        links = dependent_links
        all_web_content_items = web_content_items(links.map(&:last))

        links.group_by(&:first).each_with_object({}) do |(type, link_array), hash|
          reverse = ::Queries::DependeeExpansionRules.reverse_name_for(type).to_sym
          link_ids = link_array.map(&:last)
          items = all_web_content_items.select { |item| link_ids.include?(item.content_id) }
          expanded = dependent_expanded_items(items)
          if parent
            expanded.map { |e| e[:links] = { type.to_s.to_sym => [expanded_parent] } }
          else
            expanded.map { |e| e[:links] = {} }
          end
          hash[reverse] = expanded
        end
      end

      def dependent_links
        Link
          .where(target_content_id: content_id)
          .joins(:link_set)
          .where(link_type: rules.reverse_recursive_types)
          .order(link_type: :asc, position: :asc)
          .pluck(:link_type, :content_id)
      end

      def dependent_expanded_items(items)
        items.map do |item|
          expansion_fields = rules.expansion_fields(item.document_type.to_sym)
          item.to_h.select { |k, _v| expansion_fields.include?(k) }
        end
      end

      def web_content_items(target_content_ids)
        return [] unless target_content_ids.present?
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
