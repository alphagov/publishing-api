class GraphqlContentItemService
  class QueryResultError < StandardError; end

  def initialize(compactor)
    @compactor = compactor
  end

  def self.for_schema(schema_name)
    schema = GovukSchemas::Schema.find(frontend_schema: schema_name)
    compactor = Graphql::ContentItemCompactor.new(schema)
    new(compactor)
  end

  def process(query_result)
    error_messages = error_messages(query_result)
    if error_messages.present?
      raise QueryResultError, error_messages.join("\n")
    end

    unpublishing(query_result) || edition(query_result)
  end

private

  def edition(query_result)
    content_item = query_result.dig("data", "edition")
    @compactor.compact(content_item)
  end

  def unpublishing(query_result)
    query_result["errors"]
      &.find { _1["message"] == "Edition has been unpublished" }
      &.[]("extensions")
  end

  def error_messages(query_result)
    query_result["errors"]
      &.map { _1["message"] }
      &.reject { _1 == "Edition has been unpublished" }
  end
end
