class GraphqlContentItemService
  attr_reader :query_result

  def initialize(query_result)
    @query_result = query_result
  end

  def process
    unpublished_error_extensions || edition
  end

private

  def edition
    query_result.dig("data", "edition").tap do |content_item|
      content_item.compact!
      content_item["details"].compact!
    end
  end

  def unpublished_error_extensions
    query_result["errors"]
      &.find { _1["message"] == "Edition has been unpublished" }
      &.[]("extensions")
  end
end
