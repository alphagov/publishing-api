(import "shared/default_format.jsonnet") + {
  document_type: "get_involved",

  definitions: (import "shared/definitions/_whitehall.jsonnet") + {
    details: {
      type: "object",
      additionalProperties: false,
      properties: {
        body: { type: "string" },
        take_part_pages: {
          type: "array",
          items: {
            type: "object",
            additionalProperties: false,
            required: [
              "title",
              "description",
              "details",
            ],
            properties: {
              title: {
                type: "string",
              },
              description: {
                type: "string",
              },
              details: {
                type: "object",
                additionalProperties: false,
                required: [
                  "body",
                  "image",
                ],
                properties: {
                  body: {
                    "$ref": "#/definitions/body",
                  },
                  image: {
                    "$ref": "#/definitions/image",
                  },
                },
              },
            },
          },
        },
      },
    },
  },
  links: (import "shared/base_links.jsonnet") + {
    take_part_pages: {
       description: "The take part pages to display on this page"
    },
  },
}
