(import "shared/default_format.jsonnet") + {
  document_type: "generic_with_external_links",
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      properties: {
        external_related_links: {
          "$ref": "#/definitions/external_related_links",
        },
      },
    },
  },
}
