require "json"

class GraphqlQueryBuilder
  FRAGMENTS = Dir.glob(Rails.root.join("app/graphql/queries/fragments/_*.graphql.erb"))
                 .map { |file| file.match(/fragments\/_(.*)\.graphql\.erb\Z/)[1] }
                 .to_set
                 .freeze

  FRAGMENT_NAME_OVERRIDES = (Hash.new { |_, key| key }).merge(
    "child_taxons" => "parent_and_root_taxons",
    "parent" => "parents",
    "parent_taxons" => "parent_and_root_taxons",
    "people" => "person",
    "root_taxon" => "parent_and_root_taxons",
  ).freeze

  DEFAULT_TOP_LEVEL_FIELDS = %w[
    analytics_identifier
    base_path
    content_id
    description
    document_type
    first_published_at
    locale
    phase
    public_updated_at
    publishing_app
    publishing_request_id
    publishing_scheduled_at
    rendering_app
    scheduled_publishing_delay_seconds
    schema_name
    title
    updated_at
  ].freeze

  def initialize(schema_name)
    @schema_name = schema_name
    @content_item = {}

    unless File.exist?(path_to_content_items)
      raise "Error: can't find content item files in #{path_to_content_items}"
    end

    Dir.glob(File.join(path_to_content_items, "*")).each_with_object(@content_item) do |filename, everything_item|
      single_item = JSON.parse(File.read(filename))

      simplify_links!(single_item)

      depp_merge!(everything_item, single_item)
    end
  end

  attr_reader :schema_name, :content_item

  def build_query
    parts = [
      "<%= render \"fragments/default_top_level_fields\" %>",
      (@content_item["links"]&.keys&.map { FRAGMENT_NAME_OVERRIDES[it] }&.to_set & FRAGMENTS)&.sort&.map { |link_key| "<%= render \"fragments/#{link_key}\" %>" },
      "",
      "query #{@schema_name}($base_path: String!) {",
      "  edition(base_path: $base_path) {",
      "    ...DefaultTopLevelFields",
      build_fields(@content_item.except(*DEFAULT_TOP_LEVEL_FIELDS), indent: 4),
      "  }",
      "}",
    ]

    parts.join("\n")
  end

private

  def build_fields(data, indent: 2)
    fields = data.flat_map do |entry|
      case entry
      in [String, {}]
        nil
      in ["details", Hash => details]
        [
          "details {",
          details.map { |details_key, _| "  #{details_key}" },
          "}",
        ]
      in ["links", Hash => links]
        [
          "links {",
          links.map { |link_key, link_value| build_links_query(link_key, link_value) },
          "}",
        ]
      in [String => key, Hash => value]
        [
          "#{key} {",
          build_fields(value),
          "}",
        ]
      in [String => key, String | Numeric | true | false | nil]
        key
      end
    end
    fields.compact.join("\n").indent(indent)
  end

  def build_links_query(key, array, indent: 2)
    fragment_name = FRAGMENT_NAME_OVERRIDES[key]
    if FRAGMENTS.include?(fragment_name)
      return "...#{fragment_name.camelize}".indent(indent)
    end

    [
      "#{key} {",
      build_fields(array.first),
      "}",
    ].join("\n").indent(indent)
  end

  def path_to_content_items
    Rails.root.join("..", "content-store", "tmp", "downloads", @schema_name)
  end

  def simplify_links!(content_item)
    maximalist_links = {}

    content_item["links"].each do |link_type, array|
      maximalist_links[link_type] = [
        array.each_with_object({}) do |link, hash|
          depp_merge!(hash, link)
        end,
      ]
    end

    content_item["links"] = maximalist_links
  end

  def merge_tiebreak!(_, item_a, item_b)
    case [item_a, item_b]
    in [[], *]
      item_b
    in [*, []]
      item_a
    in [[Hash => hash_a], [Hash => hash_b]]
      depp_merge!(hash_a, hash_b)

      item_a
    else
      item_b
    end
  end

  def depp_merge!(hash_a, hash_b)
    hash_a.deep_merge!(hash_b, &method(:merge_tiebreak!))
  end
end
