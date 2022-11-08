(import "publishing_api_out.jsonnet") + {
  base_path: {
    "$ref": "#/definitions/absolute_path",
  },
  first_published_at: {
    anyOf: [
      {
        "$ref": "#/definitions/first_published_at",
      },
      {
        type: "null",
      },
    ],
  },
  public_updated_at: {
    anyOf: [
      {
        "$ref": "#/definitions/public_updated_at",
      },
      {
        type: "null",
      },
    ],
  },
  updated_at: {
    type: "string",
    format: "date-time",
  },
  publishing_scheduled_at: {
    anyOf: [
      {
        "$ref": "#/definitions/publishing_scheduled_at",
      },
      {
        type: "null",
      },
    ],
  },
  scheduled_publishing_delay_seconds: {
    anyOf: [
      {
        "$ref": "#/definitions/scheduled_publishing_delay_seconds",
      },
      {
        type: "null",
      },
    ],
  },
}
