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
      expand_links
    end

  private

    attr_reader :content_id, :expansion_rules

    def links_targetting(content_id, types)
      links_where = { target_content_id: content_id }
      links_where[:link_type] = types if types.present?
      LinkSet.joins(:links).where(links: links_where).pluck(:content_id, :link_type)
    end

    def expand_links(content_ids_path = [], link_type_path = [])
      links_for = content_ids_path.last || content_id
      allowed_link_types = allowed_link_types(link_type_path)
      in_cycle = content_ids_path.uniq != content_ids_path
      fetch_links = content_ids_path.empty? || (!in_cycle && !allowed_link_types.empty?)

      links = fetch_links ? links_targetting(links_for, allowed_link_types) : []

      if links.empty?
        valid_link_path?(link_type_path) ? content_ids_path : []
      else
        expanded_links = links.flat_map do |(content_id, link_type)|
          expand_links(content_ids_path + [content_id], link_type_path + [link_type])
        end

        expanded_links.uniq
      end
    end

    def allowed_link_types(link_type_path)
      link_type_path.empty? ? [] : expansion_rules.next_reverse_recursive_types(link_type_path)
    end

    def valid_link_path?(link_type_path)
      only_item = link_type_path.length == 1
      valid_recursion = expansion_rules.valid_link_recursion?(link_type_path.reverse)
      only_item || valid_recursion
    end
  end
end
