(import "shared/default_format.jsonnet") + {
  document_type: "email_alert_signup",
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      required: [
        "subscriber_list",
        "summary",
      ],
      properties: {
        subscriber_list: {
          type: "object",
          description: "The attributes used to match subscriber lists in email-alert-api",
          minProperties: 1,
          properties: {
            tags: {
              "$ref": "#/definitions/tags",
            },
            links: {
              type: "object",
              description: "The links used to match subscribers lists",
              additionalProperties: false,
              maxProperties: 1,
              patternProperties: {
                "^[a-z_]+$": {
                  type: "array",
                },
              },
            },
            document_type: {
              type: "string",
              description: "The document_type used to match subscribers lists",
            },
          },
        },
        email_alert_type: {
          type: "string",
          enum: [
            "policies",
            "countries",
          ],
        },
        summary: {
          "$ref": "#/definitions/email_alert_signup_summary",
        },
        breadcrumbs: {
          "$ref": "#/definitions/email_alert_signup_breadcrumbs",
        },
        govdelivery_title: {
          type: "string",
          description: "UNSUPPORTED. Use title field instead.",
        },
      },
    },
  },
}
