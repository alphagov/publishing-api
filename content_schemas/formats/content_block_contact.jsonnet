local utils = import "shared/utils/content_block_utils.jsonnet";

(import "shared/content_block.jsonnet") + {
  document_type: "content_block_contact",
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      properties: {
        description: {
          type: "string"
        },
        email_addresses: utils.embedded_object(
          {
            email_address: {
              type: "string",
              format: "email",
            },
            description: {
              type: "string",
            },
          },
          ["email_address"],
        ),
        telephones: utils.embedded_object(
             {
                telephone: {
                   type: "string",
                },
             },
             ["telephone"],
        ),
      },
    },
  },
}