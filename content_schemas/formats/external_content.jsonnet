(import "shared/default_format.jsonnet") + {
  document_type: "external_content",
  base_path: "forbidden",
  routes: "forbidden",
  description: "required",
  rendering_app: "forbidden",
  edition_links: {},
  links: {},
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      required: [
        "url",
      ],
      properties: {
        url: {
          description: "A URL for the external resource",
          type: "string",
          format: "uri",
        },
        hidden_search_terms: {
          "$ref": "#/definitions/hidden_search_terms",
        },
      },
    },
  },
}
