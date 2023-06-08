(import "shared/default_format.jsonnet") + {
  document_type: (import "shared/definitions/_corporate_information_document_types.jsonnet"),
  definitions: (import "shared/definitions/_whitehall.jsonnet") + {
    details: {
      type: "object",
      additionalProperties: false,
      properties: {
        body: {
          "$ref": "#/definitions/body",
        },
      },
    },
  },
  links: (import "shared/base_links.jsonnet") + {
    worldwide_organisation: "The Worldwide Organisation that this Worldwide Corporate Information Page belongs to",
  },
}
