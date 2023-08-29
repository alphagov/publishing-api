(import "shared/default_format.jsonnet") + {
  document_type: "field_of_operation",
  links: (import "shared/base_links.jsonnet") + {
    fatality_notices: {
        description: "Fatality notices for this field of operation"
    },
  },
}
