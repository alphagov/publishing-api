class GraphqlContentItemService
  class QueryResultError < StandardError; end

  attr_reader :query_result

  def initialize(schema_name, query_result)
    @schema = GovukSchemas::Schema.find(frontend_schema: schema_name)
    @query_result = query_result
  end

  def process
    if error_messages.present?
      raise QueryResultError, error_messages.join("\n")
    end

    unpublishing || edition
  end

private

  def edition
    content_item = query_result.dig("data", "edition")
    schema_aware_compact!(content_item, @schema)
    schema_aware_compact!(content_item["details"], @schema.dig(
      "definitions",
      "details"
    ))

    content_item
  end

  def schema_aware_compact!(content_item, schema)
    required_fields = @schema.fetch("required")
    content_item.each do |key, value|
      next unless value.nil?

      if required_fields.include?(key)
        next
        # next if it can be nil
        # raise if not
      end

      content_item.delete(key)
    end
  end

  def unpublishing
    query_result["errors"]
      &.find { _1["message"] == "Edition has been unpublished" }
      &.[]("extensions")
  end

  def error_messages
    return @error_messages if defined?(@error_messages)

    @error_messages = query_result["errors"]
      &.map { _1["message"] }
      &.reject { _1 == "Edition has been unpublished" }
  end
end
