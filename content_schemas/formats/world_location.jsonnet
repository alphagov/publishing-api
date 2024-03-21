(import "shared/default_format.jsonnet") + {
  document_type: "world_location",
  base_path: "optional",
  routes: "optional",
  definitions: (import "shared/definitions/_whitehall.jsonnet") + {
    details: {
      type: "object",
      additionalProperties: false,
      properties: {
       analytics_identifier: {
          "$ref": "#/definitions/analytics_identifier",
        },
        change_note: {
          "$ref": "#/definitions/change_note",
        },
        external_related_links: {
          "$ref": "#/definitions/external_related_links",
        },
        search_id: {
           type: "string",
           description: "A human-readable identifier used for filtering within Finder Frontend.",
        },
        tags: {
          "$ref": "#/definitions/tags",
        },
      },
    },
  },
  edition_links: (import "shared/base_edition_links.jsonnet") + {
    featured_policies: "Featured policies primarily for use with Whitehall organisations",
  },
  rendering_app: "optional",
}
