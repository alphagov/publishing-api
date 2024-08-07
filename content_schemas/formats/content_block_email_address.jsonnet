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
  edition_links: {
    primary_publishing_organisation: {
       description: "The organisation that published the content block. Corresponds to the Edition's 'Organisation' in Whitehall, and is empty for all other publishing applications.",
       maxItems: 1,
    },
  },
}
