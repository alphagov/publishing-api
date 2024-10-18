(import "shared/default_format.jsonnet") + {
  document_type: "landing_page",
  definitions: {
    details: {
      type: "object",
      additionalProperties: true,
      properties: {}
    }
  },
  edition_links: (import "shared/whitehall_edition_links.jsonnet") + {
    documents: "Documents which belong underneath this landing page",
  },
}
