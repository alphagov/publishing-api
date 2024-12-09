(import "shared/default_format.jsonnet") + {
    document_type: ["bank_holidays", "clocks_change"],
    definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      required: ["divisions"],
      properties: {
        divisions: {
            slug: "string"
            year: {
              title: "string",
              date: {
                type: 'string',
                format: 'date-time'
                 }
              notes: "string"
              bunting: {
                style: "string"
                visible: "boolean"
              } 
            }
        },
      },
    },
  },
}