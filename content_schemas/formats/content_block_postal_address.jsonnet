(import "shared/content_block.jsonnet") + {
  document_type: "content_block_postal_address",
  definitions: (import "shared/definitions/_content_block_manager.jsonnet") +  {
    details: {
      type: "object",
      additionalProperties: false,
      required: ["line_1", "town_or_city", "postcode"],
      properties: {
        line_1: {
          type: "string",
        },
        line_2: {
          type: "string",
        },
        town_or_city: {
          type: "string",
        },
        county: {
          type: "string",
        },
        postcode: {
          type: "string"
        },
        instructions_for_publishers: {
          "$ref": "#/definitions/instructions_for_publishers",
        }
      },
    },
  },
}
