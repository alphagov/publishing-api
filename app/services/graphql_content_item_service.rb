class GraphqlContentItemService
  class QueryResultError < StandardError; end

  attr_reader :query_result

  def initialize(schema_name, query_result)
    @compactor = Graphql::ContentItemCompactor.new(
      GovukSchemas::Schema.find(frontend_schema: schema_name)
    )
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
    @compactor.compact(content_item)
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
