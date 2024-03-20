(import "shared/default_format.jsonnet") + {
  document_type: "worldwide_organisation",
  definitions: (import "shared/definitions/_whitehall.jsonnet") + {
    details: {
      type: "object",
      additionalProperties: false,
      properties: {
        body: {
          "$ref": "#/definitions/body",
        },
        logo: (import "shared/definitions/_organisation_logo.jsonnet"),
        default_news_image: {
          "$ref": "#/definitions/image",
        },
        office_contact_associations: {
          type: "array",
          items: {
            type: "object",
            additionalProperties: false,
            required: [
              "office_content_id",
              "contact_content_id",
            ],
            properties: {
              office_content_id: {
                "$ref": "#/definitions/guid",
              },
              contact_content_id: {
                "$ref": "#/definitions/guid",
              },
            },
          },
        },
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
        people_role_associations: {
          type: "array",
          items: {
            type: "object",
            additionalProperties: false,
            required: [
              "person_content_id",
              "role_appointments",
            ],
            properties: {
              person_content_id: {
                "$ref": "#/definitions/guid",
              },
              role_appointments: {
                type: "array",
                items: {
                  type: "object",
                  additionalProperties: false,
                  required: [
                    "role_appointment_content_id",
                    "role_content_id",
                  ],
                  properties: {
                    role_appointment_content_id: {
                      "$ref": "#/definitions/guid",
                    },
                    role_content_id: {
                      "$ref": "#/definitions/guid",
                    },
                  },
                },
              },
            },
          },
        },
        secondary_corporate_information_pages: {
          type: "string",
          description: "A string containing sentences and links to corporate information pages that are not included in ordered_corporate_information_pages.",
        },
        social_media_links: (import "shared/definitions/_social_media_links.jsonnet"),
        world_location_names: {
          type: "array",
          items: {
            type: "object",
            additionalProperties: false,
            required: [
              "content_id",
              "name",
            ],
            properties: {
              content_id: {
                "$ref": "#/definitions/guid",
              },
              name: {
                type: "string",
              },
            },
          },
          description: "The names of the associated world locations in the same language as the worldwide organisation content.",
        },
      },
    },
  },
  edition_links: (import "shared/base_edition_links.jsonnet") + {
    contacts: "The contacts linked to offices of this Worldwide Organisation",
    corporate_information_pages: "Corporate information pages for this Worldwide Organisation",
    main_office: "The main office for this Worldwide Organisation",
    home_page_offices: "The offices, other than the main office, to be shown on the home page of this Worldwide Organisation",
    primary_role_person: "The person currently appointed to a primary role in this Worldwide Organisation",
    secondary_role_person: "The person currently appointed to a secondary role in this Worldwide Organisation",
    office_staff: "People currently appointed to office staff roles in this Worldwide Organisation",
    sponsoring_organisations: "Sponsoring organisations for this Worldwide Organisation",
    world_locations: "World Locations associated with this Worldwide Organisation",
    role_appointments: "Role appointments associated with people from this Worldwide Organisation",
    roles: "All roles associated with this Worldwide Organisation",
    world_news_stories: "All world news stories associated with this Worldwide Organisation"
  },
}
