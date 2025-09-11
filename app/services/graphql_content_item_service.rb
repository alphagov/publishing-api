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
    deep_transform_hash(query_result.dig("data", "edition"))
  end

  def deep_transform_hash(hash)
    hash.map { deep_transform(_1.to_s, _2) }.compact.to_h
  end

  def deep_transform(key, value)
    case [key, value]
    in [String, Hash]
      new_value = deep_transform_hash(value)
      [key, new_value] unless new_value == {}
    in [String, [Hash, *]]
      new_value = value.map(&method(:deep_transform_hash))
      [key, new_value] unless new_value == []
    in [String, nil | "" | [] | {}]
      nil
    else
      [key, value]
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
