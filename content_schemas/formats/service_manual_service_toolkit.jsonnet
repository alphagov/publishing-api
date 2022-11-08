(import "shared/default_format.jsonnet") + {
  document_type: "service_manual_service_toolkit",
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      properties: {
        collections: {
          type: "array",
          description: "Collections of links grouped under a title and description",
          items: {
            type: "object",
            required: [
              "title",
              "links",
            ],
            additionalProperties: false,
            properties: {
              title: {
                type: "string",
                description: "Collection title",
              },
              description: {
                type: "string",
                description: "Collection description",
              },
              links: {
                type: "array",
                description: "Array of links in this collection",
                items: {
                  type: "object",
                  required: [
                    "title",
                    "url",
                  ],
                  additionalProperties: false,
                  properties: {
                    title: {
                      type: "string",
                      description: "Link Title",
                    },
                    url: {
                      type: "string",
                      format: "uri",
                      description: "Link URL (absolute)",
                    },
                    description: {
                      type: "string",
                      description: "Link description",
                    },
                  },
                },
              },
            },
          },
        },
      },
    },
  },
}
