{
  parts: {
    type: "array",
    items: {
      type: "object",
      additionalProperties: false,
      required: [
        "title",
        "slug",
        "body",
      ],
      properties: {
        title: {
          type: "string",
        },
        slug: {
          type: "string",
          format: "uri",
        },
        summary: {
          type: "string",
        },
        body: {
          "$ref": "#/definitions/body_html_and_govspeak",
        },
      },
    },
  },
}
