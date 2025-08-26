class GraphqlContentItemService
  class QueryResultError < StandardError; end

  attr_reader :query_result

  def initialize(query_result)
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

  def error_messages
    return @error_messages if defined?(@error_messages)

    @error_messages = query_result["errors"]
      &.map { _1["message"] }
      &.reject { _1 == "Edition has been unpublished" }
  end
end
