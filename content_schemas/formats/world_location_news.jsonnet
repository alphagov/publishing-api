(import "shared/default_format.jsonnet") + {
  document_type: "world_location_news",
  definitions: (import "shared/definitions/_whitehall.jsonnet") + {
    details: {
      type: "object",
      additionalProperties: false,
      required: [
         "ordered_featured_links",
         "mission_statement",
         "ordered_featured_documents"
       ],
      properties: {
        ordered_featured_links: {
          "$ref": "#/definitions/ordered_featured_links",
        },
        mission_statement: {
          type: "string"
        },
        ordered_featured_documents: {
          "$ref": "#/definitions/ordered_featured_documents",
        },
        "world_location_news_type": {
          "type": "string",
          "enum": [
            "international_delegation",
            "world_location"
          ]
        },
      },
    },
  },
  links: (import "shared/base_links.jsonnet") + {
    ordered_contacts: "Contact details for this World Location (only used for International Delegations)",
    worldwide_organisations: "Linked Worldwide Organisations (only used for International Delegations)",
  },
}
