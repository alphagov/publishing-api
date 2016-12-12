module Queries
  # Used to return a list of content ids that are linked to a specificied
  # content id.
  #
  # Uses expansion_rules to recursively determine content ids of items that
  # indirectly are linked to a content id.
  #
  # Designed to be used to determine which links to update as part of
  # dependency resoultion.
  class LinkedTo
    def initialize(content_id, expansion_rules)
      @content_id = content_id
      @expansion_rules = expansion_rules
    end

    def call
      first_level = links_targetting(content_id)
      expanded = first_level.flat_map do |(content_id, type)|
        expand_recursive_links([content_id], [type])
      end
      content_ids = expanded.inject([]) do |memo, hash|
        only_item = hash[:link_type_path].length == 1
        valid_recursion = expansion_rules.valid_link_recursion?(hash[:link_type_path].reverse)
        only_item || valid_recursion ? memo + hash[:content_ids] : memo
      end
      content_ids.uniq
    end

  private

    attr_reader :content_id, :expansion_rules

    def links_targetting(content_id, types = nil)
      links_where = { target_content_id: content_id }
      links_where[:link_type] = types if types.present?
      LinkSet.joins(:links).where(links: links_where).pluck(:content_id, :link_type)
    end

    def expand_recursive_links(content_id_path, type_path)
      next_content_id = content_id_path.last
      allowed_types = expansion_rules.next_reverse_recursive_types(type_path)
      cycle = content_id_path.uniq != content_id_path
      current = { content_ids: content_id_path, link_type_path: type_path }
      return [current] if allowed_types.empty? || cycle
      links = links_targetting(next_content_id, allowed_types)
      expanded_links = links.flat_map do |(content_id, type)|
        expand_recursive_links(content_id_path + [content_id], type_path + [type])
      end
      [current] + expanded_links
    end
  end
end
