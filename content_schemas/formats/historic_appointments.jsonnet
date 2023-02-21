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
                 dates_in_office: (import "shared/definitions/_dates_in_office.jsonnet"),
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
