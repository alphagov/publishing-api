class Graphql::ContentItemCompactor
  def initialize(schema)
    @schema = schema
  end

  def compact(graphql_response)
    details = graphql_response["details"]
    if details
      details_required_fields = @schema.dig("definitions", "details", "required") || []
      graphql_response["details"] = compact_by_schema(
        details,
        details_required_fields,
        "#/properties/details/properties",
      )
    end
    required_fields = @schema.fetch("required", [])
    result = compact_by_schema(graphql_response, required_fields, "#/properties")
    compact_empty_links!(result)
    result
  end

private

  def compact_empty_links!(item)
    links = item["links"]
    if links.present?
      item["links"] = links.reject { |_key, linked_items| linked_items == [] }

      # Recurse through each of the linked items, compacting their links too
      item["links"].each_value do |linked_items|
        linked_items.each do |linked_item|
          compact_empty_links!(linked_item)
        end
      end
    end
  end

  def compact_by_schema(hash, required_fields, fragment)
    hash.filter do |key, value|
      # Include all fields with non-nil values
      next true unless value.nil?

      if required_fields.include?(key)
        # TODO: check the performance cost of doing this for every required nil field
        begin
          # Check if nil is a valid value for this property
          JSON::Validator.validate!(@schema, nil, fragment: "#{fragment}/#{key}")
        rescue JSON::Schema::ValidationError
          Rails.logger.warn("field #{key} is required, and null is not an valid value, but null is all we have")
        end

        # Include the field
        true
      else
        # Omit the field
        false
      end
    end
  end
end
