(import "shared/default_format.jsonnet") + {
  document_type: "mainstream_browse_page",
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      properties: {
        internal_name: {
          "$ref": "#/definitions/taxonomy_internal_name",
        },
        second_level_ordering: {
          enum: [
            "alphabetical",
            "curated",
          ],
        },
        ordered_second_level_browse_pages: {
          description: "All 2nd level browse pages under active_top_level_browse_page, with ordering preserved",
          "$ref": "#/definitions/guid_list",
        },
        groups: {
          "$ref": "#/definitions/topic_groups",
        },
      },
    },
  },
  links: (import "shared/base_links.jsonnet") + {
    top_level_browse_pages: "All top-level browse pages",
    active_top_level_browse_page: {
      description: "The top-level browse page which is active",
      maxItems: 1,
    },
    second_level_browse_pages: "All 2nd level browse pages under active_top_level_browse_page",
    related_topics: "",
  },
}
