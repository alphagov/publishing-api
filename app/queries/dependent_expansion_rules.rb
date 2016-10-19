module Queries
  module DependentExpansionRules
    extend self

    def expansion_fields(link_type)
      custom(link_type) || default_fields
    end

    def expand_field(web_content_item)
      return unless web_content_item
      web_content_item.to_h.slice(*expansion_fields(web_content_item.document_type.to_sym))
    end

    def recurse?(link_type, level_index = 0)
      recursive_link_types.any? do |t|
        t[level_index] == link_type.to_sym || t.last == link_type.to_sym
      end
    end

    def reverse_name_for(link_type)
      reverse_names[link_type.to_sym]
    end

    def recursive_link_types
      [
        [:parent],
        [:parent_taxons],
        [:ordered_related_items, :parent],
      ]
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
      ]
    end

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
