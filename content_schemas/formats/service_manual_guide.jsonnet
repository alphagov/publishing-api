(import "shared/default_format.jsonnet") + {
  document_type: "service_manual_guide",
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      required: [
        "body",
      ],
      properties: {
        show_description: {
          type: "boolean",
          description: "Display the description on the page if true. This is needed for the service standard points.",
        },
        body: {
          "$ref": "#/definitions/body",
        },
        withdrawn_notice: {
          "$ref": "#/definitions/withdrawn_notice",
        },
        header_links: {
          type: "array",
          items: {
            type: "object",
            properties: {
              title: {
                type: "string",
              },
              href: {
                "$ref": "#/definitions/anchor_href",
              },
            },
            required: [
              "title",
              "href",
            ],
          },
        },
        change_note: {
          "$ref": "#/definitions/change_note",
        },
        change_history: {
          "$ref": "#/definitions/change_history",
        },
      },
    },
    anchor_href: {
      type: "string",
      pattern: "^#.+$",
      description: "Anchor links for navigation within the same page. Format: '#anchor-link-id'",
    },
  },
  links: (import "shared/base_links.jsonnet") + {
    content_owners: "References a page of a GDS community responsible for maintaining the guide e.g. Agile delivery community, Design community",
    service_manual_topics: "References an array of 'service_manual_topic's. Not to be confused with 'topics'.",
  },
}
