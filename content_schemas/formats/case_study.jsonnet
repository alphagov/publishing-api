(import "shared/default_format.jsonnet") + {
  document_type: "case_study",
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
        image: {
          "$ref": "#/definitions/image",
        },
        format_display_type: {
          type: "string",
          enum: [
            "case_study",
          ],
        },
        first_public_at: {
          "$ref": "#/definitions/first_public_at",
        },
        change_history: {
          "$ref": "#/definitions/change_history",
        },
        tags: {
          "$ref": "#/definitions/tags",
        },
        archive_notice: {
          type: "object",
          additionalProperties: false,
          properties: {
            explanation: {
              type: "string",
            },
            archived_at: {
              format: "date-time",
            },
          },
        },
        emphasised_organisations: {
          "$ref": "#/definitions/emphasised_organisations",
        },
        brexit_no_deal_notice: {
          "$ref": "#/definitions/brexit_no_deal_notice",
        }
      },
    },
  },
  links: (import "shared/base_links.jsonnet") + {
    government: {
      description: "The government associated with this document",
      maxItems: 1,
    },
    related_policies: "",
    world_locations: "",
    worldwide_organisations: "",
  },
}
