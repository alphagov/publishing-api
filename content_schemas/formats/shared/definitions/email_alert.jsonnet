{
  email_alert_signup_breadcrumbs: {
    description: "DEPRECATED. Breadcrumbs for email alert signup. Should use parent in links as other formats do.",
    type: "array",
    items: {
      type: "object",
      additionalProperties: false,
      required: [
        "link",
        "title",
      ],
      properties: {
        link: {
          type: "string",
          format: "uri",
        },
        title: {
          type: "string",
        },
      },
    },
  },
  email_alert_signup_summary: {
    description: "DEPRECATED. No longer used.",
    type: "string",
  },
  tags: {
    type: "object",
    description: "Field used by email-alert-api to trigger email alerts for subscriptions to topics (gov.uk/topic) and policies (gov.uk/policies).",
    additionalProperties: false,
    properties: {
      browse_pages: {
        type: "array",
        items: {
          type: "string",
        },
      },
      policies: {
        type: "array",
        items: {
          type: "string",
        },
      },
    },
  },
  email_signup_link: {
    description: "Path to email signup form. TODO: Check if can be switched to use links instead",
    type: "string",
    format: "uri",
  },
}
