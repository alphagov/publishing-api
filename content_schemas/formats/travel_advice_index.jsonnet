(import "shared/default_format.jsonnet") + {
  document_type: "travel_advice_index",
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      required: [
        "email_signup_link",
      ],
      properties: {
        email_signup_link: {
          "$ref": "#/definitions/email_signup_link",
        },
        max_cache_time: {
          "$ref": "#/definitions/max_cache_time",
        },
        publishing_request_id: {
          "$ref": "#/definitions/publishing_request_id",
        },
      },
    },
  },
  links: (import "shared/base_links.jsonnet") + {
    related: "",
  },
}
