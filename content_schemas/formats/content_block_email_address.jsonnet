(import "shared/content_block.jsonnet") + {
  document_type: "content_block_email_address",
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
