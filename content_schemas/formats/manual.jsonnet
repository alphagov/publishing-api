(import "shared/default_format.jsonnet") + {
  document_type: "manual",
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      required: [
        "body",
      ],
      properties: {
        body: {
          "$ref": "#/definitions/body_html_and_govspeak",
        },
        child_section_groups: {
          "$ref": "#/definitions/manual_child_section_groups",
        },
        change_notes: {
          "$ref": "#/definitions/manual_change_notes",
        },
        organisations: {
          "$ref": "#/definitions/manual_organisations",
        },
      },
    },
  },
  links: (import "shared/base_links.jsonnet") + {
    organisations: "",
    sections: "",
    available_translations: "",
  },
}
