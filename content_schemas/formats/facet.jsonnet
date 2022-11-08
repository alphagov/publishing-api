(import "shared/default_format.jsonnet") + {
  document_type: "facet",
  base_path: "optional",
  routes: "optional",
  rendering_app: "optional",
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      required: [
        "filterable",
        "key",
        "name",
        "type",
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
            "content_id",
            "date",
            "hidden",
            "taxon",
            "text",
            "topical",
          ],
        },
        open_value: {
          description: "Value that determines the open state (the key field is in the future) of a topical facet.",
        },
        closed_value: {
          description: "Value that determines the closed state (the key field is in the past) of a topical facet.",
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
      },
    },
  },
}
