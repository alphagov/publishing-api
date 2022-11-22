{
  manual_section_parent: {
    description: "The parent manual for a manual section",
    type: "object",
    additionalProperties: false,
    required: [
      "base_path",
    ],
    properties: {
      base_path: {
        "$ref": "#/definitions/absolute_path",
      },
    },
  },
  manual_organisations: {
    description: "A manual’s organisations. TODO: Switch to use organisations in links",
    type: "array",
    items: {
      type: "object",
      additionalProperties: false,
      required: [
        "title",
        "abbreviation",
        "web_url",
      ],
      properties: {
        title: {
          type: "string",
        },
        abbreviation: {
          type: "string",
        },
        web_url: {
          type: "string",
        },
      },
    },
  },
  manual_change_notes: {
    description: "A history of changes to manuals and the associated section",
    items: {
      type: "object",
      additionalProperties: false,
      required: [
        "base_path",
        "title",
        "change_note",
        "published_at",
      ],
      properties: {
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
  manual_child_section_groups: {
    description: "Grouped sections of a manual",
    type: "array",
    items: {
      type: "object",
      additionalProperties: false,
      required: [
        "title",
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
              "title",
              "description",
              "base_path",
            ],
            additionalProperties: false,
            type: "object",
            properties: {
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
}
