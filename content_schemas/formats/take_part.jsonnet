(import "shared/default_format.jsonnet") + {
  document_type: "take_part",
  definitions: (import "shared/definitions/_whitehall.jsonnet") + {
    details: {
      type: "object",
      additionalProperties: false,
      required: [
        "body",
        "image",
      ],
      properties: {
        body: {
          "$ref": "#/definitions/body",
        },
        image: {
          "$ref": "#/definitions/image",
        },
        ordering: {
          type: "integer",
        },
      },
    },
  },
}
