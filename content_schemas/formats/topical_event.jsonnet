(import "shared/default_format.jsonnet") + {
  definitions: (import "shared/definitions/_whitehall.jsonnet") + {
    details: {
      type: "object",
      additionalProperties: false,
      properties: {
        body: {
          description: "The main content provided as HTML rendered from govspeak",
          type: "string"
        },
        about_page_link_text: {
          type: "string",
        },
        image: {
          properties: {
           url: {
             type: "string",
             format: "uri",
           },
           alt_text: {
             type: "string",
           },
          },
        },
        start_date: {
          type: "string",
          format: "date-time",
        },
        end_date: {
          type: "string",
          format: "date-time",
        },
        emphasised_organisations: {
          "$ref": "#/definitions/emphasised_organisations",
        },
        ordered_featured_documents: {
          type: "array",
          items: {
            type: "object",
            additionalProperties: false,
            required: [
              "title",
              "href",
              "image",
              "summary",
            ],
            properties: {
              title: {
                type: "string",
              },
              href: {
                type: "string",
              },
              image: {
                "$ref": "#/definitions/image",
              },
              summary: {
                type: "string",
              },
            },
          },
          description: "A set of featured documents to display for the Topical Event.",
        },
        social_media_links: (import "shared/definitions/_social_media_links.jsonnet"),
      },
    },
  },
}
