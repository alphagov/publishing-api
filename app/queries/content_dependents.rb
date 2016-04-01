module Queries
  class ContentDependents
    def initialize(content_id:, fields: [], link_sets: LinkSets.new, dependent_lookup: GetDependents.new)
      @content_id = content_id
      @fields = fields
      @link_sets = link_sets
      @dependent_lookup = dependent_lookup
    end

    def call
      return [] unless dependents?
      recursive_link_types, direct_link_types = link_types
      dependent_lookup.call(
        content_id: content_id,
        recursive_link_types: Hash[recursive_link_types].keys,
        direct_link_types: Hash[direct_link_types].keys
      )
    end

  private

    attr_reader :content_id, :fields, :dependent_lookup

    def dependents?
      (fields & fields_that_require_dependent_lookup).any?
    end

    def fields_that_require_dependent_lookup
      link_sets.values.flat_map { |link| link[:expanded_links] }.uniq
    end

    def link_types
      link_sets
        .select { |_type, set| (fields & set[:expanded_links]).any? }
        .partition { |_type, set| set[:recurse] }
    end

    def link_sets
      @link_sets.call
    end
  end
end
