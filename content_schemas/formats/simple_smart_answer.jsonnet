(import "shared/default_format.jsonnet") + {
  document_type: "simple_smart_answer",
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      required: [
        "start_button_text",
      ],
      properties: {
        start_button_text: {
          "$ref": "#/definitions/start_button_text",
        },
        body: {
          "$ref": "#/definitions/body_html_and_govspeak",
        },
        nodes: {
          description: "List of nodes consisting of questions and answers",
          type: "array",
          items: {
            description: "A node represents either a question or an answer and results in a renderable page",
            type: "object",
            additionalProperties: false,
            required: [
              "kind",
              "slug",
              "title",
            ],
            properties: {
              kind: {
                enum: [
                  "question",
                  "outcome",
                ],
              },
              slug: {
                type: "string",
              },
              title: {
                type: "string",
              },
              body: {
                "$ref": "#/definitions/body_html_and_govspeak",
              },
              options: {
                description: "Contains references to other nodes",
                type: "array",
                items: {
                  description: "An option represents a possible answer a user can select which links to another node",
                  type: "object",
                  additionalProperties: false,
                  required: [
                    "label",
                    "slug",
                    "next_node",
                  ],
                  properties: {
                    label: {
                      type: "string",
                    },
                    slug: {
                      type: "string",
                    },
                    next_node: {
                      type: "string",
                    },
                  },
                },
              },
            },
          },
        },
        external_related_links: {
          "$ref": "#/definitions/external_related_links",
        },
      },
    },
  },
}
