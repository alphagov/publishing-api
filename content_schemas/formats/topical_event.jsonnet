(import "shared/default_format.jsonnet") + {
  document_type: "topical_event",
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
          "$ref": "#/definitions/image",
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
        change_history: {
          "$ref": "#/definitions/change_history",
        },
        ordered_featured_documents: {
          "$ref": "#/definitions/ordered_featured_documents",
        },
        social_media_links: (import "shared/definitions/_social_media_links.jsonnet"),
        images: {
          type: "array",
          items: {
            "$ref": "#/definitions/image_asset",
          }
        }
      },
    },
  },
  edition_links: (import "shared/whitehall_edition_links.jsonnet")
}
