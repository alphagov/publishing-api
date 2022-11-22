(import "shared/default_format.jsonnet") + {
  document_type: "service_manual_service_standard",
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      properties: {
        body: {
          "$ref": "#/definitions/body",
        },
        poster_url: {
          type: "string",
          format: "uri",
          description: "URL to the service standard poster (absolute)",
        },
      },
    },
  },
  links: (import "shared/base_links.jsonnet") + {
    email_alert_signup: "References an email alert signup page for the service standard",
  },
}
