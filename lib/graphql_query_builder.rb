class GraphqlQueryBuilder
  MAX_LINK_DEPTH = 5 #?

  def initialize(schema_name)
    @schema_name = schema_name
    @content_item = GovukSchemas::RandomExample.for_schema(
      frontend_schema: @schema_name,
      strategy: :one_of_everything,
    )
  end

  attr_reader :schema_name, :content_item

  def build_query
    parts = [
      "query #{@schema_name}($base_path: String!) {",
      "  edition(base_path: $base_path) {",
      "    ... on #{edition_type_or_subtype(@schema_name)} {",
      build_fields(@content_item, indent: 6),
      "    }",
      "  }",
      "}",
    ]

    parts.join("\n")
  end

private

  def build_fields(data, indent: 2, link_path: [])
    fields = data.sort_by(&:first).flat_map do |entry|
      case entry
      in ["withdrawn", *]
        nil
      in [String, {} | []]
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
          links.map { |link_key, array| build_links_query(link_path + [link_key.to_sym], array) }.compact,
          "}",
        ]
      in [String => key, [Hash => value, *]]
        [
          "#{key} {",
          build_fields(value, link_path:),
          "}",
        ]
      in [String => key, Hash => value]
        [
          "#{key} {",
          build_fields(value, link_path:),
          "}",
        ]
      in [String => key, [String, *] | String | Numeric | true | false | nil]
        key
      end
    end
    fields.compact.join("\n").indent(indent)
  end

  def is_reverse_of_edition_link_type?(link_type)
    # cache this?
    Edition
      .joins(:links)
      .where(
        editions: { content_store: "live" },
        links: { link_type: ExpansionRules.reverse_to_direct_link_type(link_type) },
      )
      .exists?
  end

  def is_reverse_link_type?(link_path)
    # if "role_appointments" is at the root of the link_path, it's not the
    # reverse kind ':|
    return false if link_path == %i[role_appointments]

    link_type = link_path.last

    ExpansionRules.is_reverse_link_type?(link_type)
  end

  def build_links_query(link_path, links)
    link_type = link_path.last

    document_types = if is_reverse_link_type?(link_path)
                       flip_reversed_link_types = ExpansionRules.reverse_to_direct_link_type(link_type)

                       if flip_reversed_link_types.any? { is_reverse_of_edition_link_type?(_1) }
                         raise "I don't know how to handle reverse links that map to edition links"
                       end

                       Edition
                         .joins(document: :link_set_links)
                         .where(
                           editions: { content_store: "live" },
                           links: { link_type: flip_reversed_link_types },
                         )
                         .distinct
                         .pluck(:document_type)
                     else
                       Edition
                         .joins(document: :reverse_links)
                         .where(
                           editions: { content_store: "live" },
                           links: { link_type: },
                         )
                         .distinct
                         .pluck(:document_type)
                     end

    example_from_schema = links.first || {}

    return if document_types.empty? && example_from_schema.empty?

    link = if document_types.empty?
             example_from_schema
           else
             document_types.map { |document_type|
               ExpansionRules.expand_fields({ document_type: }, link_type:, draft: false)
             }
               .each_with_object(example_from_schema) { |item, hash| hash.deep_merge!(item) }
               .deep_stringify_keys
           end

    link.delete("details") if link["details"].blank?
    link.delete("links") if link["links"].blank?

    if link_path.size < MAX_LINK_DEPTH
      next_level_links = allowed_link_types(link_path)

      unless next_level_links.empty?
        link["links"] ||= {}

        next_level_links.each do |next_link_type|
          if link["links"][next_link_type.to_s].nil?
            link["links"][next_link_type.to_s] = []
          end
        end
      end
    end

    [
      "#{link_type} {",
      build_fields(link, link_path:),
      "}",
    ].join("\n").indent(2)
  end

  def allowed_link_types(link_path)
    ExpansionRules::MultiLevelLinks
      .new(ExpansionRules::MULTI_LEVEL_LINK_PATHS)
      .allowed_link_types(link_path)
  end

  def edition_type_or_subtype(schema_name)
    if schema_name == "ministers_index"
      "MinistersIndex"
    else
      "Edition"
    end
  end
end
