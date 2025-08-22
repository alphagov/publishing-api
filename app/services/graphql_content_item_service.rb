class GraphqlContentItemService
  attr_reader :query_result

  def initialize(query_result)
    @query_result = query_result
  end

  def process
    unpublishing || edition
  end

private

  def edition
    query_result.dig("data", "edition")
  end

  def unpublishing
    query_result["errors"]
      &.find { _1["message"] == "Edition has been unpublished" }
      &.[]("extensions")
  end
end
