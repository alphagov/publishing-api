(import "shared/default_format.jsonnet") + {
  document_type: [
    "detailed_guide",
    "detailed_guidance",
  ],
  definitions: (import "shared/definitions/_whitehall.jsonnet") + {
    details: {
      type: "object",
      additionalProperties: false,
      required: [
        "body",
        "political",
      ],
      properties: {
        attachments: {
          description: "An ordered list of asset links",
          type: "array",
          items: {
            "$ref": "#/definitions/file_attachment_asset",
          },
        },
        body: {
          "$ref": "#/definitions/body",
        },
        related_mainstream_content: {
          description: "The ordered list of related and additional mainstream content item IDs. Use in conjunction with the (unordered) `related_mainstream_content` link.",
          type: "array",
          items: {
            "$ref": "#/definitions/guid",
          },
        },
        first_public_at: {
          "$ref": "#/definitions/first_public_at",
        },
        image: {
          "$ref": "#/definitions/image",
        },
        change_history: {
          "$ref": "#/definitions/change_history",
        },
        alternative_scotland_url: {
          type: "string",
        },
        alternative_wales_url: {
          type: "string",
        },
        alternative_nothern_ireland_url: {
          type: "string",
        },
        tags: {
          "$ref": "#/definitions/tags",
        },
        government: {
          "$ref": "#/definitions/government",
        },
        political: {
          "$ref": "#/definitions/political",
        },
        emphasised_organisations: {
          "$ref": "#/definitions/emphasised_organisations",
        },
        national_applicability: {
          "$ref": "#/definitions/national_applicability",
        },
        brexit_no_deal_notice: {
          "$ref": "#/definitions/brexit_no_deal_notice",
        }
      },
    },
  },
  edition_links: (import "shared/whitehall_edition_links.jsonnet") + {
    related_guides: "",
    related_mainstream_content: "",
  },
  links: (import "shared/base_links.jsonnet") + {
    government: {
      description: "The government associated with this document",
      maxItems: 1,
    },
    related_guides: "",
    related_policies: "",
    related_mainstream_content: "",
  },
}
