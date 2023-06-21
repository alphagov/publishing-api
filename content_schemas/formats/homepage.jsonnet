(import "shared/default_format.jsonnet") + {
  document_type: ["homepage", "service_manual_homepage"],
  definitions: {
    details: {
      type: "object",
      properties: {
        promotion_slots: {
            type: "object",
            "required": [
              "url",
              "title",
              "text",
              "image_src"
            ],
            "additionalProperties": false,
            properties: {
                text: {
                    "type": "string"
                },
                title: {
                    "type": "string"
                },
                url: {
                    "type": "string"
                },
                image_src: {
                    type: "string",
                    format: "uri"
                }

            }
        }
      },
    },
  },
  links: {},
}
