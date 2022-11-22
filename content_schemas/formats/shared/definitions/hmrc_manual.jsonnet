{
  hmrc_manual_change_notes: {
    description: "A history of changes to HMRC manuals and the associated section. section_id is included and required making it different to manual_change_notes",
    type: "array",
    items: {
      type: "object",
      additionalProperties: false,
      required: [
        "section_id",
        "base_path",
        "title",
        "change_note",
        "published_at",
      ],
      properties: {
        section_id: {
          type: "string",
        },
        base_path: {
          "$ref": "#/definitions/absolute_path",
        },
        title: {
          type: "string",
        },
        change_note: {
          type: "string",
        },
        published_at: {
          type: "string",
          format: "date-time",
        },
      },
    },
  },
  hmrc_manual_child_section_groups: {
    description: "Grouped sections of an HMRC manual. Differs from manuals as section_id is required and group titles are optional.",
    type: "array",
    items: {
      type: "object",
      additionalProperties: false,
      required: [
        "child_sections",
      ],
      properties: {
        title: {
          type: "string",
        },
        child_sections: {
          type: "array",
          items: {
            required: [
              "section_id",
              "title",
              "description",
              "base_path",
            ],
            additionalProperties: false,
            type: "object",
            properties: {
              section_id: {
                type: "string",
              },
              title: {
                type: "string",
              },
              description: {
                type: "string",
              },
              base_path: {
                "$ref": "#/definitions/absolute_path",
              },
            },
          },
        },
      },
    },
  },
  hmrc_manual_breadcrumbs: {
    description: "Breadcrumbs for HMRC manuals based on section",
    type: "array",
    items: {
      type: "object",
      additionalProperties: false,
      required: [
        "base_path",
        "section_id",
      ],
      properties: {
        base_path: {
          "$ref": "#/definitions/absolute_path",
        },
        section_id: {
          type: "string",
        },
      },
    },
  },
}
