(import "shared/default_format.jsonnet") + {
  document_type: "history",

  definitions: {
    details: {
      type: "object",
      additionalProperties: true,
      required: ["body"],
      properties: {
        body: { type: "string" },
      },
    },
  },
}
