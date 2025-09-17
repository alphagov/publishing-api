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

    compact_response
  end

private

  def compact_non_required_fields(hash, required_fields)
    hash.reject { |key, value| value.nil? && required_fields.exclude?(key) }
  end
end
