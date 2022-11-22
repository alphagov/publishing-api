{
  frontend_content_id: "required",
  document_type: null,
  base_path: "required",
  routes: "required",
  redirects: "forbidden",
  title: "required",
  description: "optional",
  rendering_app: "required",
  details: "required",
  definitions: {},
  edition_links: import "base_edition_links.jsonnet",
  links: import "base_links.jsonnet",
}
