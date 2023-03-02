(import "shared/default_format.jsonnet") + {
  links: (import "shared/base_links.jsonnet") + {
    fatality_notices: {
        description: "Fatality notices for this field of operation"
    },
  },
}