(import "shared/default_format.jsonnet") + {
  document_type: "topic",
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      properties: {
        internal_name: {
          "$ref": "#/definitions/taxonomy_internal_name",
        },
        groups: {
          "$ref": "#/definitions/topic_groups",
        }
      },
    },
  },
  links: (import "shared/base_links.jsonnet") + {
    linked_items: "Includes all content ids referenced in 'details'. This is a temporary measure to expand content ids for frontends which is planned to be replaced by a dependency resolution service.",
  },
}
