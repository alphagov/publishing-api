(import "shared/content_block.jsonnet") + {
  document_type: "content_block_email_address",
  definitions: (import "shared/definitions/_content_block_manager.jsonnet") + {
    details: {
      type: "object",
      additionalProperties: false,
      required: ["email_address"],
      properties: {
        email_address: {
          type: "string",
          format: "email",
        },
        instructions_for_publishers: {
           "$ref": "#/definitions/instructions_for_publishers",
        }
      },
    },
  },
}
