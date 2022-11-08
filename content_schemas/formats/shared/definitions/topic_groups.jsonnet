{
  topic_groups: {
    description: "Lists of items with titles & paths in named groups, used for showing curated links on browse pages and topics",
    type: "array",
    items: {
      type: "object",
      additionalProperties: false,
      required: [
        "name",
        "contents",
      ],
      properties: {
        name: {
          type: "string",
        },
        description: {
          description: "DEPRECATED",
          type: "string",
        },
        contents: {
          type: "array",
          items: {
            "$ref": "#/definitions/absolute_path",
          },
        },
        content_ids: {
          description: "DEPRECATED",
          "$ref": "#/definitions/guid_list",
        },
      },
    },
  },
  service_manual_topic_groups: {
    description: "Lists of items with titles & content IDs in named groups, used for service manual topic pages",
    type: "array",
    items: {
      type: "object",
      additionalProperties: false,
      required: [
        "name",
      ],
      properties: {
        name: {
          type: "string",
        },
        description: {
          type: "string",
        },
        content_ids: {
          "$ref": "#/definitions/guid_list",
        },
      },
    },
  },
}
