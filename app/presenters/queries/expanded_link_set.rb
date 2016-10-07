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

      def parents
        @parents ||= all_parents.group_by { |e| e["parent_id"] }
      end

      def all_parents
        @all_parents ||= recursive_query(recursive_link_types.map { |t| "'#{t}'" }.join(','))
      end

      def recursive_link_types
        @recursive_link_types ||= ::Queries::DependentExpansionRules.recursive_link_types
      end

      def all_web_content_items
        @all_web_content_items ||= target_content_items.each_with_object({}) do |item, lookup|
          lookup[item.content_id] = item
        end
      end

      def target_content_items
        web_content_items(all_parents.map { |i| i["target_content_id"] }.uniq)
      end

      def expand_level(type)
        return {} unless parents[type]
        parents[type].group_by { |p| p['link_type'] }.each_with_object({}) do |(parent_type, links), hash|
          hash[parent_type.to_sym] = expand_links(links).compact
        end
      end

      def rules
        ::Queries::DependeeExpansionRules
      end

      def expand_links(links)
        links.uniq { |l| l["target_content_id"] } .map do |link|
          item = all_web_content_items[link["target_content_id"]]
          next unless item
          next_level = expand_level(link["target_content_id"]) if link['cycle'] == 'f'
          expanded_rules = rules.expansion_fields(item.document_type.to_sym)
          expanded = item.to_h.select { |k, _v| expanded_rules.include?(k) }
          expanded.merge(links: (next_level || {}).reject { |_k, v| v.empty? }) if expanded.present?
        end
      end

      def dependees
        expand_level(content_id).reject { |_k, v| v.empty? }
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
            expanded.map { |e| e[:links] = { "#{type}".to_sym => [expanded_parent] } }
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
          .where(link_type: recursive_link_types)
          .pluck(:link_type, :content_id)
      end

      def dependent_expanded_items(items)
        items.map do |item|
          expansion_fields = rules.expansion_fields(item.document_type.to_sym)
          item.to_h.select { |k, _v| expansion_fields.include?(k) }
        end
      end

      # Fetches all target_content_id where links have a target to the content_item
      # Capture path of link to prevent infinite recursion and switch flag cycle to true
      #
      # Recursion:
        # Level 0: All links with content_id of any type
        # Level 1: All links that target level 1, with the same link_type
        # Level 2: All links that target level 2, with recursive link_types included in level 1
        # Level 3: Recurse on level 2 etc.
      # Remove level 0, take all of level 1
      # only take target_content_ids of recursive link_types from level 1 and above
      def recursive_query(recursive_types = "'parent'")
        ActiveRecord::Base.connection.execute(
          <<-SQL
          WITH RECURSIVE dependees(level, link_type, target_content_id, parent_id, path, cycle) AS (
            SELECT 0 AS level, links.link_type, link_sets.content_id, link_sets.content_id, ARRAY[link_sets.content_id], FALSE
            FROM link_sets
            JOIN links on links.link_set_id = link_sets.id
            WHERE link_sets.content_id = '#{content_id}'
            UNION
            SELECT level + 1, links.link_type, links.target_content_id, link_sets.content_id AS parent_id, path || links.target_content_id, links.target_content_id = ANY(path)
            FROM dependees
            JOIN link_sets
            ON link_sets.content_id = dependees.target_content_id
            JOIN links
            ON link_sets.id = links.link_set_id
            WHERE
              level + 1 = 1 AND links.link_type IN (dependees.link_type)
              OR level + 1 > 1 AND links.link_type IN (#{recursive_types})
            AND NOT cycle
          )
          SELECT DISTINCT(target_content_id), link_type, level, parent_id, path, cycle  FROM dependees
          WHERE level = 1 OR parent_id IN (SELECT target_content_id FROM dependees WHERE level > 0 AND link_type IN (#{recursive_types}))
          AND level != 0;
        SQL
        )
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
