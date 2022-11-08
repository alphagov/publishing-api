(import "shared/default_format.jsonnet") + {
  document_type: "manual_section",
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      required: [
        "body",
        "manual",
        "organisations",
      ],
      properties: {
        body: {
          "$ref": "#/definitions/body_html_and_govspeak",
        },
        attachments: {
          description: "An ordered list of asset links",
          type: "array",
          items: {
            "$ref": "#/definitions/file_attachment_asset",
          },
        },
        manual: {
          "$ref": "#/definitions/manual_section_parent",
        },
        organisations: {
          "$ref": "#/definitions/manual_organisations",
        },
        visually_expanded: {
          type: "boolean",
          description: "A flag set by a content designer when they want the manual sections to be expanded and display without accordions.",
        },
      },
    },
  },
  links: (import "shared/base_links.jsonnet") + {
    organisations: "",
    manual: "",
    available_translations: "",
  },
}
