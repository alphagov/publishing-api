class Graphql::ContentItemCompactor
  def initialize(schema)
    @required_top_level_fields = schema.fetch("required")
    @required_details_fields = schema.fetch("definitions")
                                     .fetch("details")
                                     .fetch("required", [])
  end

  def compact(graphql_response)
    compact_response = compact_non_required_fields(graphql_response, @required_top_level_fields)

    details = compact_response["details"]
    if details.present?
      compact_response["details"] = compact_non_required_fields(details, @required_details_fields)
    end

    compact_links(compact_response)
  end

private

  def compact_non_required_fields(hash, required_fields)
    hash.reject { |key, value| value.nil? && required_fields.exclude?(key) }
  end

  def compact_links(hash)
    links = hash["links"]
    return hash if links.blank?

    hash.merge(
      "links" =>
        links
          .reject { |_link_type, content_items| content_items.empty? }
          .transform_values { |content_items| content_items.map(&method(:compact_links)) },
    )
  end
end
