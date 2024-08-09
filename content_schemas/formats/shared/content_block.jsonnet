(import "default_format.jsonnet") + {
  base_path: "forbidden",
  routes: "forbidden",
  rendering_app: "forbidden",
  edition_links: (import "base_edition_links.jsonnet") +  {
    primary_publishing_organisation: {
       description: "The organisation that published the content block. Corresponds to the Edition's 'Organisation' in Whitehall, and is empty for all other publishing applications.",
       maxItems: 1,
    },
  },
}
