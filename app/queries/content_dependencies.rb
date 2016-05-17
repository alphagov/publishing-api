module Queries
  class ContentDependencies
    def initialize(content_id:, fields: [], dependent_lookup: GetDependents.new)
      @content_id = content_id
      @fields = fields
      @dependent_lookup = dependent_lookup
    end

    def call
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

    def link_types
      @link_types ||= affected_link_types.select { |t| (rules.expansion_fields(t) & fields).any? }
    end

    def affected_link_types
      @affected_link_types ||= dependent_lookup.affected_link_types(content_id)
    end

    def rules
      dependent_lookup.rules
    end

    def partition(link_types)
      link_types.partition { |link_type| rules.recurse?(link_type) }
    end
  end
end
