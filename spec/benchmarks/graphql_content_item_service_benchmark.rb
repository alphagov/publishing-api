DATE_PATTERN = /^\d{4}-\d{2}-\d{2}/

require_relative "./content-store/app/lib/hash_sorter"
require_relative "./content-store/app/presenters/content_type_resolver"
require_relative "./content-store/app/presenters/expanded_links_presenter"
require_relative "./content-store/app/presenters/content_item_presenter"

class ContentItem < OpenStruct; end

RSpec.describe GraphqlContentItemService do
  test_cases = [
    { base_path: "/government/news/government-sets-out-strategy-to-be-positive-for-youth", schema_name: "news_article" },
    { base_path: "/treasure", schema_name: "answer", theme_tune: "https://youtu.be/Q58Gm18-IMY" },
  ]

  test_cases.each do |test_case|
    base_path, schema_name = test_case.values_at(:base_path, :schema_name)

    it "should render #{schema_name} similar to content-store (#{base_path})" do
      edition = Edition.live.find_by(base_path: base_path)
      content_item = ContentItem.new(**Presenters::EditionPresenter.new(edition).for_content_store(0))
      content_store_representation = ContentItemPresenter.new(content_item).as_json

      # We don't care about suggested_ordered_related_items
      content_store_representation.fetch("links", {}).delete("suggested_ordered_related_items")

      File.write(
        RSpec.configuration.benchmark_content_store_examples_dir.join("#{schema_name}_#{base_path.parameterize}_content-store.json"),
        JSON.pretty_generate(deep_prune_hash(deep_sort(content_store_representation))),
        )

      query = File.read(Rails.root.join("app/graphql/queries/#{schema_name}.graphql"))
      result = PublishingApiSchema.execute(query, variables: { base_path: base_path }).to_hash
      graphql_representation = GraphqlContentItemService.for_edition(edition).process(result).deep_stringify_keys
      File.write(
        RSpec.configuration.benchmark_content_store_examples_dir.join("#{schema_name}_#{base_path.parameterize}_graphql.json"),
        JSON.pretty_generate(deep_prune_hash(deep_sort(graphql_representation))),
        )
    end
  end

  def deep_sort(value)
    if value.is_a?(Hash)
      value.transform_values { deep_sort(_1) }.sort.to_h
    elsif value.is_a?(Array)
      value.map(&method(:deep_sort))
    else
      value
    end
  end

  def deep_prune_hash(hash)
    hash.map { deep_prune(_1, _2) }.compact.to_h
  end

  def deep_prune(key, value)
    case [key, value]
    in [String, Hash]
      [key, deep_prune_hash(value)]
    in [String, [Hash, *]]
      [key, value.map(&method(:deep_prune_hash))]
    in ["withdrawn", *]
      nil
    in [String, DATE_PATTERN]
      [key, value.sub(/(#{DATE_PATTERN}).*/, '\1')]
    else
      [key, value]
    end
  end
end
