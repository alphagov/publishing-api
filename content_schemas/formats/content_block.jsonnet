(import "shared/default_format.jsonnet") + {
  document_type: [
    "content_block_time_period",
    "content_block_tax",
    "content_block_contact",
    "content_block_pension",
  ],
  definitions: {
    details: {
      type: "object",
      additionalProperties: true,
      properties: {}
    }
  },
  base_path: "optional",
  routes: "optional",
  content_id_alias: "optional",
  instructions_to_publishers: "optional",
  rendering_app: "forbidden",
  edition_links: (import "shared/base_edition_links.jsonnet") +  {
    primary_publishing_organisation: {
       description: "The organisation that published the content block. Corresponds to the Edition's 'Organisation' in Whitehall, and is empty for all other publishing applications.",
       maxItems: 1,
    },
  },
}
