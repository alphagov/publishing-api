(import "shared/default_format.jsonnet") + {
  document_type: "worldwide_office",
  definitions: (import "shared/definitions/_whitehall.jsonnet") + {
    details: {
      type: "object",
      additionalProperties: false,
      properties: {
        access_and_opening_times: {
           type: [
             "string",
             "null",
           ],
           description: "The access and opening times for this Worldwide Office.",
         },
      },
    },
  },
  links: (import "shared/base_links.jsonnet") + {
    contact: "Contact details for this Worldwide Office",
    worldwide_organisation: "The Worldwide Organisation that this Worldwide Office belongs to",
  },
}
