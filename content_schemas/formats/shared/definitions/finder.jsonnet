{
  finder_document_noun: {
    description: "How to refer to documents when presenting the search results",
    type: "string",
  },
  finder_default_documents_per_page: {
    description: "Specify this to paginate results",
    type: "integer",
  },
  finder_default_order: {
    description: "DEPRECATED: Use “sort” property",
    type: "string",
  },
  finder_sort: {
    description: "These are the options for sorting the finder",
    type: "array",
    items: {
      type: "object",
      additionalProperties: false,
      required: [
        "key",
        "name",
      ],
      properties: {
        key: {
          description: "Rummager field name, with an optional preceding “-” to sort in descending order",
          type: "string",
        },
        name: {
          description: "Label for the sort option",
          type: "string",
        },
        default: {
          description: "Indicates if this should be the default sort option",
          type: "boolean",
        },
      },
    },
  },
  finder_filter: {
    description: "This is the fixed filter that scopes the finder",
    type: "object",
    additionalProperties: false,
    properties: {
      all_part_of_taxonomy_tree: {
        type: "array",
        items: {
          type: "string",
        },
      },
      content_purpose_subgroup: {
        type: "array",
        items: {
          type: "string",
        },
      },
      content_purpose_supergroup: {
        type: "array",
        items: {
          type: "string",
        },
      },
      content_store_document_type: {
        type: "array",
        items: {
          type: "string",
        },
      },
      document_type: {
        type: "string",
      },
      email_document_supertype: {
        type: "array",
        items: {
          type: "string",
        },
      },
      format: {
        type: "string",
      },
      has_official_document: {
        type: "boolean"
      },
      organisations: {
        type: "array",
        items: {
          type: "string",
        },
      },
      policies: {
        type: "array",
        items: {
          type: "string",
        },
      },
    },
  },
  finder_reject_filter: {
    description: "A fixed filter that rejects documents which match the conditions",
    type: "object",
    additionalProperties: false,
    properties: {
      content_purpose_supergroup: {
        type: "array",
        items: {
          type: "string",
        },
      },
      content_store_document_type: {
        type: "array",
        items: {
          type: "string",
        },
      },
      email_document_supertype: {
        type: "array",
        items: {
          type: "string",
        },
      },
      policies: {
        type: "array",
        items: {
          type: "string",
        },
      },
      link: {
        type: "array",
        items: {
          type: "string",
        },
      },
    },
  },
  finder_facets: {
    description: "The facets shown to the user to refine their search.",
    type: "array",
    items: {
      type: "object",
      additionalProperties: false,
      required: [
        "key",
        "filterable",
        "display_as_result_metadata",
      ],
      properties: {
        filter_key: {
          description: "The exact rummager field name for this facet. Allows 'key' to be aliased to a rummager filter field",
          type: "string",
        },
        filter_value: {
          description: "A preset filter value that is applied when a checkbox is selected",
          type: "string"
        },
        key: {
          description: "The rummager field name used for this facet.",
          type: "string",
        },
        keys: {
          description: "Field names used for the taxon drop down.",
          type: "array",
          items: {
            type: "string",
          },
        },
        filterable: {
          description: "This must be true to show the facet to users.",
          type: "boolean",
        },
        display_as_result_metadata: {
          description: "Include this in search result metadata. Can be set for non-filterable facets.",
          type: "boolean",
        },
        large: {
          description: "When set to true, the height of the option select facet will be larger",
          type: "boolean",
        },
        open_on_load: {
          description: "When set to true, the option select facet will always be open on page load",
          type: "boolean",
        },
        name: {
          description: "Label for the facet.",
          type: "string",
        },
        preposition: {
          description: "Text used to augment the description of the search when the facet is used.",
          type: "string",
        },
        short_name: {
          type: "string",
        },
        type: {
          description: "Defines the UI component and how the facet is queried from the search API",
          type: "string",
          enum: [
            "autocomplete",
            "checkbox",
            "date",
            "hidden",
            "hidden_clearable",
            "nested",
            "radio",
            "research_and_statistics",
            "official_documents",
            "taxon",
            "text",
            "topical"
          ],
        },
        main_facet_key: {
          description: "If this facet is a subfacet, a reference point back to the main facet.",
          type: "string",
        },
        sub_facet_key: {
          description: "The key field name used for the subcategory of this facet.",
          type: "string",
        },
        sub_facet_name: {
          description: "The human readable label of the field name used for the subcategory of this facet.",
          type: "string",
        },
        nested_facet: {
          description: "Indicates whether this facet has nested sub facets within allowed values or not.",
          type: "boolean"
        },
        allowed_values: {
          description: "Possible values to show for non-dynamic select facets. All values are shown regardless of the search.",
          type: "array",
          items: {
            "$ref": "#/definitions/label_value_pair_with_sub_facets",
          },
        },
        option_lookup: {
          description: "A map of keys to values that can be used to associate allowed_values with multiple values",
          type: "object",
          additionalProperties: true,
          patternProperties: {
            "^[a-z_]+$": {
              type: "array",
              items: {
                type: "string"
              }
            }
          }
        },
        open_value: {
          description: "Value that determines the open state (the key field is in the future) of a topical facet.",
          "$ref": "#/definitions/label_value_pair",
        },
        closed_value: {
          description: "Value that determines the closed state (the key field is in the past) of a topical facet.",
          "$ref": "#/definitions/label_value_pair",
        },
        combine_mode: {
          description: "Specifies how to combine with other facets",
          type: "string",
          enum: [
            "and",
            "or",
          ],
          default: "and",
        },
        show_option_select_filter: {
          description: "Controls whether Option Select Facet displays a filter field",
          type: "boolean",
        },
        hide_facet_tag: {
          description: "Causes the facet to not have a facet tag shown in a finder",
          type: "boolean"
        }
      },
    },
  },
  finder_show_summaries: {
    type: "boolean",
  },
  finder_signup_link: {
    anyOf: [
      {
        type: "string",
      },
      {
        type: "null",
      },
    ],
  },
  finder_summary: {
    anyOf: [
      {
        type: "string",
      },
      {
        type: "null",
      },
      {
        "$ref": "#/definitions/multiple_content_types",
      },
    ],
  },
  finder_beta: {
    description: "Indicates if finder is in beta. TODO: Switch to top-level phase label",
    anyOf: [
      {
        type: "boolean",
      },
      {
        type: "null",
      },
    ],
  },
}
