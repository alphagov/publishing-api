class Graphql::ContentItemCompactor
  def initialize(schema)
    @schema = schema
  end

  def compact(graphql_response)
    compact_response = compact_non_required_fields(graphql_response, required_top_level_fields)

    details = compact_response["details"]
    if details.present?
      compact_response["details"] = compact_non_required_fields(details, required_details_fields)
    end

    compact_response
  end

private

  def compact_non_required_fields(hash, required_fields)
    hash.reject { |key, value| value.nil? && !required_fields.include?(key) }
  end

  def required_top_level_fields
    # NOTE: will be populated from the relevant schema
    []
  end

  def required_details_fields
    # NOTE: will be populated from the relevant schema
    []
  end
end
