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
    query_result.dig("data", "edition").tap do |content_item|
      content_item.compact!
      content_item["details"].compact!
    end
  end

  def unpublishing
    query_result["errors"]
      &.find { _1["message"] == "Edition has been unpublished" }
      &.[]("extensions")
  end
end
