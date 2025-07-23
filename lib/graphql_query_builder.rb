#!/usr/bin/env ruby

require "json"

class GraphqlQueryBuilder
  SPECIAL_LINK_TYPES = %w[
    available_translations
  ].freeze

  FRAGMENTS = Dir.glob(Rails.root.join("app/graphql/queries/fragments/_*.graphql.erb"))
                 .map { |file| file.match(/fragments\/_(.*)\.graphql\.erb\Z/)[1] }
                 .to_set
                 .freeze

  FRAGMENT_NAME_OVERRIDES = (Hash.new { |_, key| key }).merge(
    "parent" => "parents",
    "parent_taxons" => "parent_and_root_taxons",
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

  REVERSE_LINK_TYPES = {
    "children" => "parent",
    "document_collections" => "documents",
    "policies" => "working_groups",
    "child_taxons" => "parent_taxons",
    "level_one_taxons" => "root_taxon",
    "part_of_step_navs" => "pages_part_of_step_nav",
    "related_to_step_navs" => "pages_related_to_step_nav",
    "secondary_to_step_navs" => "pages_secondary_to_step_nav",
    "role_appointments" => "TODO - can be person or role, depending on the expected type of its parent",
    "ministers" => "ministerial",
  }.freeze

  def initialize(old_response, use_fragments)
    @data = old_response
    @use_fragments = use_fragments
  end

  def build_query
    parts = if @use_fragments
              [
                "<%= render \"fragments/default_top_level_fields\" %>",
                (@data["links"]&.keys&.map { FRAGMENT_NAME_OVERRIDES[it] }&.to_set & FRAGMENTS)&.sort&.map { |link_key| "<%= render \"fragments/#{link_key}\" %>" },
                "",
                "query #{@data['schema_name']}($base_path: String!, $locale: String!) {",
                "  edition(base_path: $base_path, locale: $locale) {",
                "    ...DefaultTopLevelFields",
                "    #{build_fields(@data.except(*DEFAULT_TOP_LEVEL_FIELDS))}",
                "  }",
                "}",
              ]
            else
              [
                "query #{@data['schema_name']}($base_path: String!, $locale: String!) {",
                "edition(base_path: $base_path, locale: $locale) {",
                "  #{build_fields(@data)}",
                "  }",
                "}",
              ]
            end
    parts.join("\n")
  end

private

  def build_fields(data, indent = 4)
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
          links.map { |link_key, link_value| "  #{build_links_query(link_key, link_value, indent + 2)}" },
          "}",
        ]
      in [String => key, String | Numeric | true | false | nil]
        key
      end
    end
    fields.compact.join("\n#{' ' * indent}")
  end

  def build_links_query(key, array, indent)
    fragment_name = FRAGMENT_NAME_OVERRIDES[key]
    return "...#{fragment_name.camelize}" if @use_fragments && FRAGMENTS.include?(fragment_name)

    link_type = REVERSE_LINK_TYPES[key] || key
    reverse = REVERSE_LINK_TYPES.key?(key)

    if SPECIAL_LINK_TYPES.include?(key)
      [
        "#{key} {",
        " " * (indent + 2) + build_fields(array.first, indent + 2),
        "#{' ' * indent}}",
      ].join("\n")
    else
      [
        "#{key}: links_of_type(type: \"#{link_type}\"#{', reverse: true' if reverse}) {",
        " " * (indent + 2) + build_fields(array.first, indent + 2),
        "#{' ' * indent}}",
      ].join("\n")
    end
  end
end
