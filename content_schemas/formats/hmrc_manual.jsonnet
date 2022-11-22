(import "shared/default_format.jsonnet") + {
  document_type: "hmrc_manual",
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      required: [
        "child_section_groups",
      ],
      properties: {
        body: {
          "$ref": "#/definitions/body",
        },
        child_section_groups: {
          "$ref": "#/definitions/hmrc_manual_child_section_groups",
        },
        change_notes: {
          "$ref": "#/definitions/hmrc_manual_change_notes",
        },
        organisations: {
          "$ref": "#/definitions/manual_organisations",
        },
        tags: {
          "$ref": "#/definitions/tags",
        },
      },
    },
  },
}
