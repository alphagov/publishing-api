(import "shared/default_format.jsonnet") + {
  document_type: "person",
  definitions: (import "shared/definitions/_whitehall.jsonnet") + {
    details: {
      type: "object",
      additionalProperties: false,
      properties: {
        analytics_identifier: {
          "$ref": "#/definitions/analytics_identifier",
        },
        body: {
          "$ref": "#/definitions/body_html_and_govspeak",
        },
        full_name: {
          type: "string",
          description: "Name of the person, including titles and any letters, eg: 'Sir Lord Snoopy DOG'",
        },
        minister: {
          type: "boolean",
        },
        privy_counsellor: {
          type: "boolean",
        },
        image: {
          "$ref": "#/definitions/image",
        },
      },
    },
  },
}
