(import "shared/default_format.jsonnet") + {
  document_type: "working_group",
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      properties: {
        attachments: {
          description: "An ordered list of asset links",
          type: "array",
          items: {
            "$ref": "#/definitions/file_attachment_asset",
          },
        },
        email: {
          type: "string",
        },
        body: {
          "$ref": "#/definitions/body",
        },
      },
    },
  },
}
