(import "shared/default_format.jsonnet") + {
  document_type: "content_block_postal_address",
  base_path: "forbidden",
  routes: "forbidden",
  rendering_app: "forbidden",
  definitions: {
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
        }
      },
    },
  },
}
