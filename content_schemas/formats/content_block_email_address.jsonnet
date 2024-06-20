(import "shared/default_format.jsonnet") + {
  document_type: "content_block_email_address",
  base_path: "forbidden",
  routes: "forbidden",
  rendering_app: "forbidden",
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      required: ["email_address"],
      properties: {
        email_address: {
          type: "string",
          format: "email",
        },
      },
    },
  },
}
