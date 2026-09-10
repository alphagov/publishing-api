(import "shared/default_format.jsonnet") + {
  document_type: [
    "mini_site_landing",
  ],
  definitions: (import "shared/definitions/_whitehall.jsonnet") + {
    details: {
      type: "object",
      additionalProperties: false,
      required: [
        "body",
      ],
      properties: {
        body: {
          "$ref": "#/definitions/body",
        },
        emphasised_organisations: {
          "$ref": "#/definitions/emphasised_organisations",
        },
        social_media_links: (import "shared/definitions/_social_media_links.jsonnet"),
        images: {
          type: "array",
          items: {
            "$ref": "#/definitions/image_asset",
          },
        },
      },
    },
  },
  edition_links: (import "shared/whitehall_edition_links.jsonnet")
}
