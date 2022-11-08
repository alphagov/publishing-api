(import "shared/default_format.jsonnet") + {
  document_type: "government",
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      properties: {
        started_on: {
          type: "string",
          format: "date-time",
        },
        ended_on: {
          type: [
            "string",
            "null",
          ],
          format: "date-time",
        },
        current: {
          type: "boolean",
        },
      },
    },
  },
}
