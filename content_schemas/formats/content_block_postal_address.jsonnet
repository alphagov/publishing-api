(import "shared/content_block.jsonnet") + {
  document_type: "content_block_postal_address",
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      required: ["line_1", "town_or_city", "postcode", "friendly_id"],
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
        friendly_id: {
          "$ref": "#/definitions/friendly_id",
        },
      },
    },
  },
}
