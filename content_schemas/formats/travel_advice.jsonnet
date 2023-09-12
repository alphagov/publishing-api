(import "shared/default_format.jsonnet") + {
  document_type: "travel_advice",
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      required: [
        "country",
        "updated_at",
        "reviewed_at",
        "change_description",
        "alert_status",
        "email_signup_link",
        "parts",
      ],
      properties: {
        country: {
          "$ref": "#/definitions/country",
        },
        updated_at: {
          type: "string",
          format: "date-time",
        },
        reviewed_at: {
          type: "string",
          format: "date-time",
        },
        change_description: {
          type: "string",
        },
        alert_status: {
          type: "array",
          items: {
            type: "string",
          },
        },
        email_signup_link: {
          "$ref": "#/definitions/email_signup_link",
        },
        image: {
          "$ref": "#/definitions/image_asset",
        },
        document: {
          "$ref": "#/definitions/file_attachment_asset",
        },
        parts: {
          "$ref": "#/definitions/parts",
        },
        max_cache_time: {
          "$ref": "#/definitions/max_cache_time",
        },
        publishing_request_id: {
          "$ref": "#/definitions/publishing_request_id",
        },
      },
    },
    country: {
      type: "object",
      additionalProperties: false,
      required: [
        "slug",
        "name",
      ],
      properties: {
        name: {
          type: "string",
        },
        slug: {
          type: "string",
        },
        synonyms: {
          type: "array",
          items: {
            type: "string",
          },
        },
      },
    },
  },
  links: (import "shared/base_links.jsonnet") + {
    related: "",
  },
}
