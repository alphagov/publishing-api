(import "shared/default_format.jsonnet") + {
  document_type: "place",
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      properties: {
        external_related_links: {
          "$ref": "#/definitions/external_related_links",
        },
        introduction: {
          "$ref": "#/definitions/body_html_and_govspeak",
        },
        more_information: {
          "$ref": "#/definitions/body_html_and_govspeak",
        },
        need_to_know: {
          "$ref": "#/definitions/body_html_and_govspeak",
        },
        place_type: {
          type: "string",
        },
      },
    },
  },
}
