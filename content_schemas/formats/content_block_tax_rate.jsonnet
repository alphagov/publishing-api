(import "shared/default_format.jsonnet") + {
  document_type: "content_block_tax_rate",
  base_path: "forbidden",
  routes: "forbidden",
  rendering_app: "forbidden",
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      required: ["band", "income", "rate"],
      properties: {
        band: {
          type: "string",
        },
        income: {
          type: "string",
        },
        rate: {
          type: "string",
        }
      },
    },
  },
}
