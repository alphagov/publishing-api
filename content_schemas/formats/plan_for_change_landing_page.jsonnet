(import "shared/default_format.jsonnet") + {
  document_type: "plan_for_change_landing_page",
  definitions: {
    details: {
      type: "object",
      additionalProperties: true,
      properties: {}
    }
  },
  edition_links: (import "shared/whitehall_edition_links.jsonnet") + {
    documents: "Documents which belong underneath this plan for change landing page",
  },
}
