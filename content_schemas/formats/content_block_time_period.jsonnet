local utils = import "shared/utils/content_block_utils.jsonnet";

(import "shared/content_block.jsonnet") + {
  document_type: "content_block_time_period",
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      required: ["date_time"],
      properties: {
        note: {
          type: "string"
        },
        description: {
          type: "string"
        },
        date_time: {
          type: "object",
          additionalProperties: false,
          required: ["start", "end"],
          properties: {
            start: {
              type: "object",
              additionalProperties: false,
              properties: {
                date: {
                  type: "string",
                  pattern: "^[1-9][0-9]{3}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[0-1])$",
                },
                time: {
                  type: "string",
                  pattern: "^(0[0-9]|1[0-9]|2[0-3]):[0-5][0-9]$",
                }
              }
            },
            end: {
              type: "object",
              additionalProperties: false,
              properties: {
                date: {
                  type: "string",
                  pattern: "^[1-9][0-9]{3}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[0-1])$",
                },
                time: {
                  type: "string",
                  pattern: "^(0[0-9]|1[0-9]|2[0-3]):[0-5][0-9]$",
                }
              }
            },
          },
        },
      },
    },
  },
}

