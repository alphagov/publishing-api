(import "shared/default_format.jsonnet") + {
  document_type: "unpublishing",
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      required: [
        "unpublished_at",
      ],
      properties: {
        explanation: {
          type: [
            "string",
            "null",
          ],
        },
        unpublished_at: {
          type: "string",
          format: "date-time",
        },
        alternative_url: {
          type: [
            "string",
            "null",
          ],
          format: "uri",
        },
        public_updated_at: {
          "$ref": "#/definitions/public_updated_at",
        },
      },
    },
  },
}
