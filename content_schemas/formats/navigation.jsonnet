(import "shared/default_format.jsonnet") + {
  document_type: "navigation",
  base_path: "optional",
  routes: "optional",
  rendering_app: "optional",
  definitions: {
    details: {
      type: "object",
      additionalProperties: true,
      properties: {
        slug: {
          type: "string",
        },
        title: {
          type: "string",
          description: "DEPRECATED: this has the same name and data as the top level title field, which should be used instead",
        },
        description: {
          type: [
            "string",
            "null",
          ],
          description: "DEPRECATED: this has the same name and data as the top level descriptions field, which should be used instead",
        },
        menu_items: {
          type: "string",
        },
      },
    },
  },
  links: (import "shared/base_links.jsonnet"),
}
