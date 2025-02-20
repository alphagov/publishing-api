local utils = import "shared/utils/content_block_utils.jsonnet";

(import "shared/content_block.jsonnet") + {
  document_type: "content_block_pension",
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      properties: {
        description: {
          type: "string"
        },
        rates: utils.embedded_object(
          {
            amount: {
              type: "string",
              pattern: "£[0-9]+\\.[0-9]+",
            },
            cadence: {
              type: "string",
              enum: ["a day", "a week", "a month", "a year"],
            },
            description: {
              type: "string",
            },
          },
          ["amount", "cadence"],
        ),
      },
    },
  },
}

