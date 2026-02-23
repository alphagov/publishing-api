(import "shared/default_format.jsonnet") + {
  document_type: "topical_event_about_page",
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      required: [
        "body",
      ],
      properties: {
        read_more: {
          type: "string",
        },
        body: {
          "$ref": "#/definitions/body",
        },
        headers: {
          "$ref": "#/definitions/nested_headers",
        },
      },
    },
  },
  edition_links: (import "shared/whitehall_edition_links.jsonnet")
}
