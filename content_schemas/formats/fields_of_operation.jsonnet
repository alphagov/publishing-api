(import "shared/default_format.jsonnet") + {
  document_type: [
    "fields_of_operation"
  ],
  links: (import "shared/base_links.jsonnet") + {
    fields_of_operation: {
        description: "Link to an individual field of operation"
    },
  },
}
