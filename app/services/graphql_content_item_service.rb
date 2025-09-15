class GraphqlContentItemService
  class QueryResultError < StandardError; end

  def initialize(compactor)
    @compactor = compactor
  end

  def self.for_schema(schema_name)
    schema = GovukSchemas::Schema.find(frontend_schema: schema_name)

    new(
      Graphql::ContentItemCompactor.new(schema),
    )
  end

  def process(query_result)
    error_messages = get_error_messages(query_result)
    if error_messages.present?
      raise QueryResultError, error_messages.join("\n")
    end

    get_unpublishing(query_result) || get_edition(query_result)
  end

private

  def get_edition(query_result)
    edition = query_result.dig("data", "edition")
    @compactor.compact(edition)
  end

  def get_unpublishing(query_result)
    query_result["errors"]
      &.find { _1["message"] == "Edition has been unpublished" }
      &.[]("extensions")
  end

  def get_error_messages(query_result)
    query_result["errors"]
      &.map { _1["message"] }
      &.reject { _1 == "Edition has been unpublished" }
  end
end
