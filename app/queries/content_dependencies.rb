module Queries
  class ContentDependencies
    def initialize(content_id:, fields: [], direction: :dependents)
      @content_id = content_id
      @fields = fields
      @direction = direction

      case direction
      when :dependents
        @dependent_lookup = GetDependents.new
        @rules = Queries::ExpansionRules
      when :dependees
        @dependent_lookup = GetDependees.new
        @rules = Queries::ExpansionRules::Reverse
      end
    end

    def call
      case direction
      when :dependents
        link_types = affected_link_types_for_dependents
      when :dependees
        link_types = affected_link_types_for_dependees
      end

      return [] unless link_types.present?

      recursive, direct = partition(link_types)

      dependent_lookup.call(
        content_id: content_id,
        recursive_link_types: recursive,
        direct_link_types: direct,
      )
    end

  private

    attr_reader :content_id, :fields, :dependent_lookup, :direction, :rules

    def affected_link_types_for_dependents
      link_types = Link.where(target_content_id: @content_id).pluck(:link_type).uniq
      link_types.select { |t| (rules.expansion_fields(t) & fields).any? }
    end

    def affected_link_types_for_dependees
      link_set = LinkSet.find_by!(content_id: @content_id)
      link_types = link_set.links.pluck(:link_type).uniq
      link_types.select { |t| (rules.expansion_fields(t) & fields).any? }
    end

    def partition(link_types)
      link_types.partition { |link_type| rules.recurse?(link_type) }
    end
  end
end
