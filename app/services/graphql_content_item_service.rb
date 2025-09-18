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

    # commit deep stringify then deep sort
    deep_sort_hash_keys((unpublishing || edition).deep_stringify_keys)
  end

private

  # move to separate class
  # requires pre-stringified (or consistently classed) keys
  def deep_sort_hash_keys(hash)
    hash.map { |key, value|
      case value
      in Hash
        [key, deep_sort_hash_keys(value)]
      in [Hash, *]
        [key, value.map(&method(:deep_sort_hash_keys))]
      else
        [key, value]
      end
    }.sort.to_h
  end

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
