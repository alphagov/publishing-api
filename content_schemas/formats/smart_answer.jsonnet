(import "shared/default_format.jsonnet") + {
  document_type: "smart_answer",
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      properties: {
        hidden_search_terms: {
          "$ref": "#/definitions/hidden_search_terms",
        },
        external_related_links: {
          "$ref": "#/definitions/external_related_links",
        },
      },
    },
  },
}
