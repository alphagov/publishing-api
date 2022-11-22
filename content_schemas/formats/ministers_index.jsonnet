(import "shared/default_format.jsonnet") + {
  document_type: "ministers_index",
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      optional: ['reshuffle'],
      properties: {
        reshuffle: {
          message: "string",
        },
      },
    },
  },
}
