(import "shared/default_format.jsonnet") + {
  definitions: (import "shared/definitions/_whitehall.jsonnet") + {
    body: {
      type: "string",
      description: "main body of text for worldwide organisation pages",
    },
    details: {
      type: "object",
      additionalProperties: false,
      properties: {
      },
    },
  },
}
