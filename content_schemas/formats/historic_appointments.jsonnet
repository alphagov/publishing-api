(import "shared/default_format.jsonnet") + {
  document_type: "historic_appointments",
  definitions: (import "shared/definitions/_whitehall.jsonnet") + {
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
                 image: {
                    "$ref": "#/definitions/image",
                 },
               }
            }
        }
      },
    },
  },
  links: (import "shared/base_links.jsonnet") + {
    historical_accounts: {
       description: "The historical appointments associated with this role"
    },
  },
}
