(import "shared/default_format.jsonnet") + {
  document_type: [
    "guidance",
    "form",
    "foi_release",
    "promotional",
    "notice",
    "correspondence",
    "research",
    "official_statistics",
    "transparency",
    "standard",
    "statutory_guidance",
    "independent_report",
    "national_statistics",
    "corporate_report",
    "policy_paper",
    "decision",
    "map",
    "regulation",
    "international_treaty",
    "impact_assessment",
  ],
  definitions: (import "shared/definitions/_whitehall.jsonnet") + {
    details: {
      type: "object",
      additionalProperties: false,
      required: [
        "body",
        "documents",
        "political",
      ],
      properties: {
        attachments: {
          description: "An ordered list of asset links",
          type: "array",
          items: {
            "$ref": "#/definitions/publication_attachment_asset",
          },
        },
        featured_attachments: {
          description: "An ordered list of attachments to feature below the document",
          type: "array",
          uniqueItems: true,
          items: {
            type: "string",
          },
        },
        document_type_label: {
          description: "a human readable version of the document type",
          type: "string",
        },
        body: {
          "$ref": "#/definitions/body",
        },
        documents: {
          "$ref": "#/definitions/attachments_with_thumbnails",
        },
        first_public_at: {
          "$ref": "#/definitions/first_public_at",
        },
        change_history: {
          "$ref": "#/definitions/change_history",
        },
        emphasised_organisations: {
          "$ref": "#/definitions/emphasised_organisations",
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
    people: "People that are associated with this document, typically the person part of a role association",
    related_statistical_data_sets: "",
    roles: "Government roles that are associated with this document, typically the role part of a role association",
    world_locations: "",
  },
  links: (import "shared/base_links.jsonnet") + {
    government: {
      description: "The government associated with this document",
      maxItems: 1,
    },
    related_policies: "",
    related_statistical_data_sets: "",
    topical_events: "",
    world_locations: "",
    roles: "Government roles that are associated with this document, typically the role part of a role association",
    people: "People that are associated with this document, typically the person part of a role association",
  },
}
