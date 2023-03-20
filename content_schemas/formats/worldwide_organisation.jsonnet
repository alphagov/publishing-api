(import "shared/default_format.jsonnet") + {
  definitions: (import "shared/definitions/_whitehall.jsonnet") + {
    details: {
      type: "object",
      additionalProperties: false,
      properties: {
        body: {
          "$ref": "#/definitions/body",
        },
        logo: (import "shared/definitions/_organisation_logo.jsonnet"),
        ordered_corporate_information_pages: {
          type: "array",
          items: {
            type: "object",
            additionalProperties: false,
            required: [
              "content_id",
              "title",
            ],
            properties: {
              content_id: {
                "$ref": "#/definitions/guid",
              },
              title: {
                type: "string",
              },
            },
          },
          description: "A set of links to corporate information pages to display for the worldwide organisation.",
        },
        social_media_links: (import "shared/definitions/_social_media_links.jsonnet"),
      },
    },
  },
  links: (import "shared/base_links.jsonnet") + {
    corporate_information_pages: "Corporate information pages for this Worldwide Organisation",
    ordered_contacts: "Contact details for this Worldwide Organisation",
    sponsoring_organisations: "Sponsoring organisations for this Worldwide Organisation",
    world_locations: "World Locations associated with this Worldwide Organisation"
  },
}
