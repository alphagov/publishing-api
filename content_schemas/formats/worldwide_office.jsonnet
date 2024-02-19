(import "shared/default_format.jsonnet") + {
  document_type: "worldwide_office",
  definitions: (import "shared/definitions/_whitehall.jsonnet") + {
    details: (import "shared/definitions/_worldwide_office.jsonnet"),
  },
  links: (import "shared/base_links.jsonnet") + {
    contact: "Contact details for this Worldwide Office",
    worldwide_organisation: "The Worldwide Organisation that this Worldwide Office belongs to",
  },
}
