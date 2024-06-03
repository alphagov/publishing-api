(import "shared/default_format.jsonnet") + {
  document_type: "link_collection",
  base_path: "optional",
  routes: "optional",
  rendering_app: "optional",
  title: "required",
  redirects: "optional",
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      properties: {
        link_items: {
          type: "array",
          items: {
            type: "object",
            additionalProperties: false,
            required: [
              "title",
              "url"
            ],
            properties: {
              title: {
                type: "string"
              },
              url: {
                type: "string"
              }
            }
          }
        }
      }
    }
  }
}
