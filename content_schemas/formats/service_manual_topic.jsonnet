(import "shared/default_format.jsonnet") + {
  document_type: "service_manual_topic",
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      properties: {
        visually_collapsed: {
          type: "boolean",
          description: "A flag set by a content designer when they want the sections of a topic to be collapsed into an accordion. This will likely be used when there are many items in the topic.",
        },
        groups: {
          "$ref": "#/definitions/service_manual_topic_groups",
        },
        withdrawn_notice: {
          "$ref": "#/definitions/withdrawn_notice",
        },
      },
    },
  },
  links: (import "shared/base_links.jsonnet") + {
    linked_items: "Includes all content ids referenced in 'details'. This is a temporary measure to expand content ids for frontends which is planned to be replaced by a dependency resolution service.",
    content_owners: "References a page of a GDS community responsible for maintaining the guide e.g. Agile delivery community, Design community",
    email_alert_signup: "References an email alert signup page for this topic",
  },
}
