(import "shared/default_format.jsonnet") + {
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
