(import "shared/default_format.jsonnet") + {
  document_type: "shared_navigation",
  base_path: "optional",
  routes: "optional",
  rendering_app: "optional",
  definitions: (import "shared/definitions/_whitehall.jsonnet") + {
    details: {
      type: "object",
      additionalProperties: false,
      required: [
        "menu_items",
      ],
      properties: {
        menu_items: {
          type: "array",
          items: {
            type: "object",
            // As we get a better sense of what a Navigation content item should look
            // like, we can be more prescriptive about what the menu_item structure
            // should look like. For now, leave it as very permissive.
            // The intention is that each object in `menu_items` has a content_id
            // that references one of the `navigation_items` links.
          },
        },
      },
    },
  },
  edition_links: (import "shared/whitehall_edition_links.jsonnet") + {
    navigation_items: "Content IDs of documents that are part of this navigation.",
  },
  links: (import "shared/base_links.jsonnet") + {
    navigation_items: "Content IDs of documents that are part of this navigation.",
  }
}
