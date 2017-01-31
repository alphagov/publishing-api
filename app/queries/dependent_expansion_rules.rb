module Queries
  module DependentExpansionRules
    using Refinements::ArraySequence
    extend self

    def expansion_fields(link_type)
      custom(link_type) || default_fields
    end

    def expand_field(web_content_item)
      web_content_item.to_h.slice(*expansion_fields(web_content_item.document_type.to_sym))
    end

    def recurse?(link_type, level_index = 0)
      recursive_link_types.any? do |t|
        t.values_at(level_index, -1).include?(link_type.to_sym)
      end
    end

    def reverse_name_for(link_type)
      reverse_names[link_type.to_sym]
    end

    # eg: ['parent', 'parent_taxons', 'parent'] would expand the parent at
    # level one, parent_taxons at level two, and parents for all levels
    # greater then n, (the size of the array), the last element being the
    # "sticky" recursive element. so for array of size 1, it would recurse on just
    # that element.
    def recursive_link_types
      [
        [:parent],
        [:parent_taxons],
        [:taxons, :parent_taxons],
        [:ordered_related_items, :mainstream_browse_pages, :parent],
      ]
    end

    def valid_link_recursion?(link_types)
      link_types = link_types.map(&:to_sym)
      recursive_link_types.any? do |compare|
        prefix_match = link_types.first(compare.count) == compare.first(link_types.count)
        suffix = link_types[compare.count..-1] || []
        prefix_match && (suffix.empty? || suffix.to_set == Set[compare.last])
      end
    end

    def next_reverse_recursive_types(reverse_link_type_path)
      reverse_link_types = reverse_link_type_path.map(&:to_sym)
      next_allowed_types = recursive_link_types.each_with_object([]) do |link_path, memo|
        sticky = link_path.last
        # strip path to not include sticky
        without_sticky = reverse_link_types.inject([]) do |types, item|
          types << item
          types.uniq == [sticky] ? types.uniq : types
        end
        # determine if this array is within the link types and which index
        index = link_path.index_of_sequence(without_sticky.reverse)
        memo << sticky if index == link_path.index(sticky)
        memo << link_path[index - 1] if index.present? && index > 0
      end
      next_allowed_types.uniq
    end

    def next_level(type, current_level)
      group = recursive_link_types.find { |e| e.include?(type.to_sym) }
      group[current_level] || group.last
    end

    def reverse_recursive_types
      reverse_names.keys
    end

  private

    def custom(link_type)
      {}[link_type]
    end

    def default_fields
      [
        :analytics_identifier,
        :api_path,
        :base_path,
        :content_id,
        :description,
        :document_type,
        :locale,
        :public_updated_at,
        :schema_name,
        :title,
        :withdrawn,
      ]
    end

    # Ensure when modifying the values to also include them in
    # govuk-content-schemas LINK_NAMES_ADDED_BY_PUBLISHING_API array
    # in FrontendSchemaGenerator
    def reverse_names
      {
        parent: "children",
        documents: "document_collections",
        working_groups: 'policies',
        parent_taxons: "child_taxons",
      }
    end
  end
end
