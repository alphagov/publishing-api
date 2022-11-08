(import "shared/default_format.jsonnet") + {
  document_type: "vanish",
  rendering_app: "forbidden",
  routes: "required",
  redirects: "forbidden",
  title: "forbidden",
  description: "forbidden",
  details: "forbidden",
  edition_links: {},
  links: {},
  generate: {
    publisher: false,
    frontend: false,
  },
}
