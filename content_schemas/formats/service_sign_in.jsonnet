(import "shared/default_format.jsonnet") + {
  document_type: "service_sign_in",
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      required: [
        "choose_sign_in",
      ],
      properties: {
        choose_sign_in: {
          "$ref": "#/definitions/choose_sign_in",
        },
        create_new_account: {
          "$ref": "#/definitions/create_new_account"
        }
      }
    },
    choose_sign_in: {
      type: "object",
      additionalProperties: false,
      required: [
        "title",
        "slug",
        "options",
      ],
      properties: {
        title: {
          type: "string",
        },
        slug: {
          type: "string",
          format: "uri",
        },
        description: {
          "$ref": "#/definitions/body_html_and_govspeak",
        },
        tracking_code: {
          type: "string"
        },
        tracking_domain: {
          type: "string"
        },
        tracking_name: {
          type: "string"
        },
        options: {
          type: "array",
          additionalProperties: false,
          required: [
            "text",
            "url",
          ],
          items: {
            type: "object",
            properties: {
              text: {
                type: "string",
              },
              url: {
                type: "string",
                format: "uri",
              },
              hint_text: {
                type: "string",
              }
            }
          },
        },
      }
    },
    create_new_account: {
      type: "object",
      additionalProperties: false,
      required: [
        "title",
        "slug",
        "body",
      ],
      properties: {
        title: {
          type: "string",
        },
        slug: {
          type: "string",
          format: "uri",
        },
        body: {
          "$ref": "#/definitions/body_html_and_govspeak",
        },
      },
    },
  },
}
