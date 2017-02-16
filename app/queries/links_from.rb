module Queries
  class LinksFrom
    def self.call(content_id, allowed_link_types: nil, parent_content_ids: [])
      return {} if allowed_link_types && allowed_link_types.empty?
      where = { "link_sets.content_id": content_id }
      where[:link_type] = allowed_link_types if allowed_link_types
      links = Link
        .joins(:link_set)
        .where(where)
        .where.not(target_content_id: parent_content_ids)
        .order(link_type: :asc, position: :asc)
        .pluck(:link_type, :target_content_id)

      grouped = links
        .group_by(&:first)
        .map { |type, values| [type.to_sym, values.map(&:last)] }

      Hash[grouped]
    end
  end
end
