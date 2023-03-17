(import "shared/default_format.jsonnet") + {
  definitions: (import "shared/definitions/_whitehall.jsonnet") + {
    details: {
      type: "object",
      additionalProperties: false,
      properties: {
        casualties: {
          type: "object",
          description: "A list of casualties associated with a given fatality notice",
        },
      },
    },
  },
  links: (import "shared/base_links.jsonnet") + {
    fatality_notices: {
      description: "Fatality notices for this field of operation"
    },
  },
}
