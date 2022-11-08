{
  govuk_request_id: {
    type: [
      "string",
      "null"
    ]
  },
  access_limited: {
    type: "object",
    additionalProperties: false,
    properties: {
      users: {
        type: "array",
        items: {
          type: "string",
        },
      },
      organisations: {
        "$ref": "#/definitions/guid_list",
        description: "A list of organisation content ids permitted access to this item",
      },
      auth_bypass_ids: {
        "$ref": "#/definitions/guid_list",
        description: "Deprecated: auth_bypass_ids should be sent as a separate field",
      },
    },
  },
  analytics_identifier: {
    anyOf: [
      {
        type: "string",
      },
      {
        type: "null",
      },
    ],
    description: "A short identifier we send to Google Analytics for multi-valued fields. This means we avoid the truncated values we would get if we sent the path or slug of eg organisations.",
  },
  description: {
    type: "string",
  },
  description_optional: {
    anyOf: [
      {
        "$ref": "#/definitions/description",
      },
      {
        type: "null",
      },
    ],
  },
  details: {
    type: "object",
    additionalProperties: false,
    properties: {},
  },
  update_type: {
    enum: [
      "major",
      "minor",
      "republish",
    ],
  },
  title: {
    type: "string",
  },
  title_optional: {
    type: "string",
  },
  multiple_content_types: {
    type: "array",
    items: {
      type: "object",
      additionalProperties: false,
      required: [
        "content_type",
        "content",
      ],
      properties: {
        content_type: {
          type: "string",
        },
        content: {
          type: "string",
        },
      },
    },
  },
  change_note: {
    description: "Change note for the most recent update",
    type: [
      "string",
      "null",
    ],
  },
  change_history: {
    type: "array",
    items: {
      type: "object",
      additionalProperties: false,
      properties: {
        public_timestamp: {
          type: "string",
          format: "date-time",
        },
        note: {
          type: "string",
          description: "A summary of the change",
        },
      },
      required: [
        "public_timestamp",
        "note",
      ],
    },
  },
  withdrawn_notice: {
    type: "object",
    additionalProperties: false,
    properties: {
      explanation: {
        type: "string",
      },
      withdrawn_at: {
        format: "date-time",
      },
    },
  },
  body: {
    description: "The main content provided as HTML rendered from govspeak",
    type: "string",
  },
  body_html_and_govspeak: {
    description: "The main content provided as HTML with the govspeak markdown it's rendered from",
    anyOf: [
      {
        "$ref": "#/definitions/multiple_content_types",
      },
    ],
  },
  first_published_at: {
    description: "The date the content was first published.  Automatically determined by the publishing-api, unless overridden by the publishing application.",
    type: "string",
    format: "date-time",
  },
  public_updated_at: {
    description: "When the content was last significantly changed (a major update). Shown to users.  Automatically determined by the publishing-api, unless overridden by the publishing application.",
    type: "string",
    format: "date-time",
  },
  publishing_scheduled_at: {
    description: "When this content was last scheduled for publishing. Determined by the publishing intent sent by the publishing API.",
    type: "string",
    format: "date-time",
  },
  scheduled_publishing_delay_seconds: {
    description: "The delay between the most recent scheduled and actual publishing times. Determined by the content store based on the publishing intent.",
    type: "integer",
  },
  publishing_request_id: {
    description: "A unique identifier used to track publishing requests to rendered content",
    oneOf: [
      { type: "string" },
      { type:"null" },
    ],
  },
  payload_version: {
    description: "Counter to indicate when the payload was generated",
    type: "integer",
  },
}
