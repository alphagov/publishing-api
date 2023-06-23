(import "shared/default_format.jsonnet") + {
  document_type: [
    "call_for_evidence",
    "closed_call_for_evidence",
    "open_call_for_evidence",
    "call_for_evidence_outcome",
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
        body: {
          "$ref": "#/definitions/body",
        },
        opening_date: {
          type: "string",
          format: "date-time",
        },
        closing_date: {
          type: "string",
          format: "date-time",
        },
        government: {
          "$ref": "#/definitions/government",
        },
        political: {
          "$ref": "#/definitions/political",
        },
        image: {
          "$ref": "#/definitions/image",
        },
        held_on_another_website_url: {
          type: "string",
        },
        first_public_at: {
          "$ref": "#/definitions/first_public_at",
        },
        change_history: {
          "$ref": "#/definitions/change_history",
        },
        national_applicability: {
          "$ref": "#/definitions/national_applicability",
        },
        emphasised_organisations: {
          "$ref": "#/definitions/emphasised_organisations",
        },
        documents: {
          "$ref": "#/definitions/attachments_with_thumbnails",
        },
        ways_to_respond: {
          type: "object",
          additionalProperties: false,
          properties: {
            link_url: {
              type: "string",
            },
            email: {
              type: "string",
            },
            postal_address: {
              type: "string",
            },
            attachment_url: {
              type: "string",
            },
          },
        },
        final_outcome_publication_date: {
          type: "string",
          format: "date-time",
        },
        final_outcome_detail: {
          type: "string",
        },
        final_outcome_documents: {
          "$ref": "#/definitions/attachments_with_thumbnails",
        },
        final_outcome_attachments: {
          type: "array",
          uniqueItems: true,
          items: {
            type: "string",
          },
        },
        tags: {
          "$ref": "#/definitions/tags",
        },
      },
    },
  },
  edition_links: (import "shared/whitehall_edition_links.jsonnet") + {
    people: "People that are associated with this document, typically the person part of a role association",
    roles: "Government roles that are associated with this document, typically the role part of a role association",
  },
  links: (import "shared/base_links.jsonnet") + {
    government: {
      description: "The government associated with this document",
      maxItems: 1,
    },
    related_policies: "",
    topical_events: "",
    people: "People that are associated with this document, typically the person part of a role association",
    roles: "Government roles that are associated with this document, typically the role part of a role association",
  },
}
