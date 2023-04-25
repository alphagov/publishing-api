{
  image_with_srcset: {
    type: "object",
    additionalProperties: false,
    required: [
      "url",
    ],
    properties: {
      url: {
        description: "URL to the image. The image should be in a suitable resolution for display on the page.",
        type: "string",
        format: "uri",
      },
      srcset: {
        description: "List of images URLs with sizes that can be used to create a srcset.",
        type: "array",
        items: {
            type: "object",
            additionalProperties: false,
            properties: {
                url: { type: "string", format: "uri" },
                size: { type: "string" },
            }
        }
      },
      alt_text: {
        type: "string",
      },
      caption: {
        anyOf: [
          {
            type: "string",
          },
          {
            type: "null",
          },
        ],
      },
      credit: {
        anyOf: [
          {
            type: "string",
          },
          {
            type: "null",
          },
        ],
      },
    },
  },
}