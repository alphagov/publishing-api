(import "shared/default_format.jsonnet") + {
  document_type: "worldwide_office",
  definitions: (import "shared/definitions/_whitehall.jsonnet") + {
    details: {
      type: "object",
      additionalProperties: false,
      properties: {
        access_and_opening_times: {
           type: [
             "string",
             "null",
           ],
           description: "The access and opening times for this Worldwide Office.",
        },
        type: {
          type: [
            "string",
            "null",
          ],
          description: "The type of Worldwide Office.",
        },
        services: {
          type: "array",
          uniqueItems: true,
          items: {
            type: "object",
            additionalProperties: false,
            properties: {
              title: {
                type: [
                  "string",
                  "null",
                ],
                description: "The name of the service provided by this Worldwide Office.",
              },
              type: {
                type: [
                  "string",
                  "null",
                ],
                description: "The type of service provided by this Worldwide Office.",
              }
            }
          }
        },
      },
    },
  },
  edition_links: (import "shared/base_edition_links.jsonnet") + {
    contact: "Contact details for this Worldwide Office",
    parent: {
      description: "The parent content item.",
      maxItems: 1,
    },
    worldwide_organisation: "The Worldwide Organisation that this Worldwide Office belongs to",
  },
}
