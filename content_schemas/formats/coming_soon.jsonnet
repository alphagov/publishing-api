(import "shared/default_format.jsonnet") + {
  document_type: "coming_soon",
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      required: ["publish_time"],
      properties: {
        publish_time: {
          type: "string",
          format: "date-time",
        },
        public_updated_at: {
          "$ref": "#/definitions/public_updated_at",
        },
      },
    },
  },
}
