class Graphql::ContentItemCompactor
  def initialize(schema)
    @schema = schema
  end

  # TODO - details
  # TODO - links with empty arrays

  def compact(graphql_response)
    required_fields = @schema.fetch("required", [])
    graphql_response.filter do |key, value|
      # Include all fields with non-nil values
      next true unless value.nil?

      if required_fields.include?(key)
        # TODO check the performance cost of doing this for every required nil field
        begin
          # Check if nil is a valid value for this property
          JSON::Validator.validate!(@schema, nil, fragment: "#/properties/#{key}")
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