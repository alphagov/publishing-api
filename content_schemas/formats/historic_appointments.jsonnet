(import "shared/default_format.jsonnet") + {
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      required: ["appointments_without_historical_accounts"],
      properties: {
        appointments_without_historical_accounts: {
            type: "array",
            items: {
               type: "object",
               additionalProperties: false,
               properties: {
                 title: {
                     type: "string"
                 },
                 dates_in_office: {
                     type: "array",
                     items: {
                        type: "object",
                        additionalProperties: false,
                        properties: {
                            start_year: { type: "integer" },
                            end_year: { type: "integer" },
                        }
                     }
                 },
                 image_url: {
                    type: "string"
                 }
               }
            }
        }
      },
    },
  },
}
