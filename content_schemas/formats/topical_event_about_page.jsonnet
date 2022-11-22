(import "shared/default_format.jsonnet") + {
  document_type: "topical_event_about_page",
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      required: [
        "read_more",
        "body",
      ],
      properties: {
        read_more: {
          type: "string",
        },
        body: {
          "$ref": "#/definitions/body",
        },
      },
    },
  },
}
