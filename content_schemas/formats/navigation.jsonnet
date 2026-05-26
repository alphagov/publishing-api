(import "shared/default_format.jsonnet") + {
  document_type: "navigation",
  base_path: "optional",
  routes: "optional",
  rendering_app: "optional",
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
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
          type: "array",
          items: {
            type: "object",
            required: [
              "content_id",
            ],
            properties: {
              content_id: {
                "$ref": "#/definitions/guid"
              },
            },
          },
        },
      },
    },
  },
  links: (import "shared/base_links.jsonnet") + {
    documents: "Documents which belong to this navigation",
  },
  edition_links: (import "shared/whitehall_edition_links.jsonnet") + {
    documents: "Documents which belong to this navigation",
  }
}
