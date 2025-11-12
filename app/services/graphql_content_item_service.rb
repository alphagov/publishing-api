class GraphqlContentItemService
  class QueryResultError < StandardError; end

  def initialize(auto_reverse_linker:, compactor:)
    @auto_reverse_linker = auto_reverse_linker
    @compactor = compactor
  end

  def self.for_edition(edition)
    schema = GovukSchemas::Schema.find(frontend_schema: edition.schema_name)

    new(
      auto_reverse_linker: Graphql::AutoReverseLinker.new(edition),
      compactor: Graphql::ContentItemCompactor.new(schema),
    )
  end

  def process(query_result)
    error_messages = get_error_messages(query_result)
    if error_messages.present?
      raise QueryResultError, error_messages.join("\n")
    end

    deep_sort(get_unpublishing(query_result) || get_edition(query_result))
  end

private

  def get_edition(query_result)
    edition = query_result.dig("data", "edition")

    @auto_reverse_linker.insert_links(
      @compactor.compact(edition),
    )
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

  def deep_sort(content_item)
    content_item.deep_stringify_keys.map { |key, value|
      case value
      in Hash
        [key, deep_sort(value)]
      in [Hash, *]
        [key, value.map(&method(:deep_sort))]
      else
        [key, value]
      end
    }.sort.to_h
  end
end
