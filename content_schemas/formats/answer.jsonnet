(import "shared/default_format.jsonnet") + {
  document_type: "answer",
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      properties: {
        body: {
          "$ref": "#/definitions/body_html_and_govspeak",
        },
        external_related_links: {
          "$ref": "#/definitions/external_related_links",
        },
      },
    },
  },
}
