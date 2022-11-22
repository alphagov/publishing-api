{
  step_by_step_nav: {
    type: "object",
    additionalProperties: false,
    required: [
      "title",
      "introduction",
      "steps",
    ],
    properties: {
      title: {
        type: "string"
      },
      introduction: {
        "$ref": "#/definitions/body_html_and_govspeak",
      },
      steps: {
        type: "array",
        items: {
          "$ref": "#/definitions/individual_step"
        }
      }
    }
  },
  individual_step: {
    type: "object",
    additionalProperties: false,
    required: [
      "title",
      "contents"
    ],
    properties: {
      title: {
        type: "string"
      },
      logic: {
        type: "string",
        enum: [
          "and",
          "or"
        ]
      },
      contents: {
        type: "array",
        items: {
          oneOf: [
            { "$ref": "#/definitions/step_item_paragraph" },
            { "$ref": "#/definitions/step_item_list" },
          ]
        }
      }
    }
  },
  step_item_paragraph: {
    type: "object",
    additionalProperties: false,
    required: [
      "type",
      "text"
    ],
    properties: {
      type: {
        type: "string"
      },
      text: {
        type: "string"
      },
    }
  },
  step_item_list: {
    type: "object",
    additionalProperties: false,
    required: [
      "type",
      "contents"
    ],
    properties: {
      type: {
        type: "string",
      },
      style: {
        type: "string",
        enum: [
          "choice",
          "required",
          "optional"
        ]
      },
      contents: {
        type: "array",
        items: {
          type: "object",
          additionalProperties: false,
          required: [
            "text"
          ],
          properties: {
            href: {
              type: "string",
              format: "uri"
            },
            text: {
              type: "string"
            },
            context: {
              type: "string"
            }
          }
        }
      }
    }
  }
}
