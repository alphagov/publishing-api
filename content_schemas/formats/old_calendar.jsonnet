(import "shared/default_format.jsonnet") + {
  document_type: "calendar",
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      properties: {
        body: {
          "$ref": "#/definitions/body",
        }
      }
    }
  }
}
