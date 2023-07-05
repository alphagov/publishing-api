(import "shared/default_format.jsonnet") + {
  document_type: [
    "finder",
    "search"
  ],
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      required: [
        "document_noun",
        "facets",
      ],
      properties: {
        beta: {
          "$ref": "#/definitions/finder_beta",
        },
        beta_message: {
          anyOf: [
            {
              type: "string",
            },
            {
              type: "null",
            },
          ],
        },
        no_index: {
          type: "boolean",
        },
        generic_description: {
          type: "boolean",
        },
        document_noun: {
          "$ref": "#/definitions/finder_document_noun",
        },
        default_documents_per_page: {
          "$ref": "#/definitions/finder_default_documents_per_page",
        },
        logo_path: {
          type: "string",
        },
        default_order: {
          "$ref": "#/definitions/finder_default_order",
        },
        sort: {
          "$ref": "#/definitions/finder_sort",
        },
        filter: {
          "$ref": "#/definitions/finder_filter",
        },
        reject: {
          "$ref": "#/definitions/finder_reject_filter",
        },
        facets: {
          "$ref": "#/definitions/finder_facets",
        },
        format_name: {
          type: "string",
        },
        label_text: {
          type: "string",
        },
        show_summaries: {
          "$ref": "#/definitions/finder_show_summaries",
        },
        signup_link: {
          "$ref": "#/definitions/finder_signup_link",
        },
        canonical_link: {
          type: "boolean",
        },
        summary: {
          "$ref": "#/definitions/finder_summary",
        },
      },
    },
  },
  links: (import "shared/base_links.jsonnet") + {
    related: "",
    email_alert_signup: "",
    available_translations: "",
  },
}
