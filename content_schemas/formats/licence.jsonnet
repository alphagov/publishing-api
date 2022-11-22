(import "shared/default_format.jsonnet") + {
  document_type: "licence",
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      required: [
        "licence_identifier",
      ],
      properties: {
        will_continue_on: {
          "$ref": "#/definitions/will_continue_on",
        },
        continuation_link: {
          description: "Link to licence competent authority.",
          type: "string",
          format: "uri",
        },
        licence_short_description: {
          description: "One line curated description, will appear in Licence Finder results.",
          type: "string",
        },
        licence_overview: {
          "$ref": "#/definitions/body_html_and_govspeak",
        },
        licence_identifier: {
          description: "Unique ID for a licence, starting with an LGSL code.",
          type: "string",
        },
        external_related_links: {
          "$ref": "#/definitions/external_related_links",
        },
      },
    },
  },
}
