{
  nested_headers: {
    type: "array",
    minItems: 1,
    items: {
      type: "object",
      additionalProperties: false,
      required: [
        "text",
        "level",
        "id",
      ],
      properties: {
        text: {
          type: "string",
        },
        level: {
          type: "integer",
        },
        id: {
          type: "string",
        },
        headers: {
          "$ref": "#/definitions/nested_headers",
        },
      },
    },
  },
}
