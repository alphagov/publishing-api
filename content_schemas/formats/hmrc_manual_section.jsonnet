(import "shared/default_format.jsonnet") + {
  document_type: "hmrc_manual_section",
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      required: [
        "section_id",
        "manual",
      ],
      properties: {
        section_id: {
          type: "string",
        },
        breadcrumbs: {
          "$ref": "#/definitions/hmrc_manual_breadcrumbs",
        },
        body: {
          "$ref": "#/definitions/body",
        },
        manual: {
          "$ref": "#/definitions/manual_section_parent",
        },
        organisations: {
          "$ref": "#/definitions/manual_organisations",
        },
        child_section_groups: {
          "$ref": "#/definitions/hmrc_manual_child_section_groups",
        },
      },
    },
  },
}
