module Queries
  class ContentDependents
    def initialize(content_id:, fields: [], dependent_lookup: GetDependents.new)
      @content_id = content_id
      @fields = fields
      @dependent_lookup = dependent_lookup
    end

    def call
      link_types = affected_link_types
      return [] unless link_types.present?

      recursive, direct = partition(link_types)

      dependent_lookup.call(
        content_id: content_id,
        recursive_link_types: recursive,
        direct_link_types: direct,
      )
    end

  private

    attr_reader :content_id, :fields, :dependent_lookup

    def affected_link_types
      link_set = LinkSet.find_by!(content_id: @content_id)
      link_types = link_set.links.pluck(:link_type).uniq
      link_types.select { |t| (rules.expansion_fields(t) & fields).any? }
    end

    def partition(link_types)
      link_types.partition { |link_type| rules.recurse?(link_type) }
    end

    def rules
      Queries::ExpansionRules
    end
  end
end
