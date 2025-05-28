local utils = import "shared/utils/content_block_utils.jsonnet";

(import "shared/content_block.jsonnet") + {
  document_type: "content_block_pension",
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      properties: {
        block_attributes: {
            type: "object",
            required: ["description"],
            properties: {
                description: {
                    type: "string",
                },
                rates: utils.embedded_object(
                    {
                        amount: {
                            type: "string",
                            pattern: "^£{1}[1-9]{1,3}(,\\d{3})*(\\.\\d{2})?",
                        },
                        frequency: {
                            type: "string",
                            enum: ["a day", "a week", "a month", "a year"],
                        },
                        description: {
                            type: "string",
                        },
                    },
                    ["amount", "frequency"],
                ),
            },
        },
        field_orders: {
            type: "object",
            properties: {
                default_order: {
                    type: "array",
                    contains: {
                        type: "string",
                    },
                },
            },
        },
      },
    },
  },
}

