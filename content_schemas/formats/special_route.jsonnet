(import "shared/default_format.jsonnet") + {
  title: "optional",
  rendering_app: "optional",
  details: "optional",
  definitions: {
    details: {
      type: "object",
      additionalProperties: true,
      properties: {}
    }
  }
}
