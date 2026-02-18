(import "shared/default_format.jsonnet") + {
  document_type: "history",
  definitions: (import "shared/definitions/_whitehall.jsonnet") + {
    details: {
      type: "object",
      additionalProperties: false,
      required: ["body"],
      properties: {
        lead_paragraph: {
          description: "Optional text that appears above the main content",
          type: "string",
        },
        body: {
          "$ref": "#/definitions/body"
        },
        images: {
          type: "array",
          items: {
            "$ref": "#/definitions/image_asset",
          }
        },
        headers: {
          "$ref": "#/definitions/nested_headers"
        }
      },
    },
  },
}
