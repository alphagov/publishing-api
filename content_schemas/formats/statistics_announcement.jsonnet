(import "shared/default_format.jsonnet") + {
  document_type: [
    "national_statistics_announcement",
    "official_statistics_announcement",
    "statistics_announcement",
    "national",
    "official",
  ],
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      required: [
        "display_date",
        "state",
        "format_sub_type",
      ],
      properties: {
        cancellation_reason: {
          type: "string",
        },
        cancelled_at: {
          type: "string",
          format: "date-time",
        },
        latest_change_note: {
          type: "string",
        },
        previous_display_date: {
          type: "string",
        },
        display_date: {
          type: "string",
        },
        state: {
          type: "string",
          enum: [
            "cancelled",
            "confirmed",
            "provisional",
          ],
        },
        format_sub_type: {
          type: "string",
          enum: [
            "national",
            "official",
          ],
        },
      },
    },
  },
  links: (import "shared/base_links.jsonnet") + {
    organisations: "",
    policy_areas: "",
  },
}
