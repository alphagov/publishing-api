local utils = import "shared/utils/content_block_utils.jsonnet";

(import "shared/content_block.jsonnet") + {
  document_type: "content_block_contact",
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      properties: {
        description: {
          type: "string"
        },
        contact_type: {
          type: "string",
          enum: [
            "General",
            "Freedom of Information",
            "Media enquiries",
          ],
          default: "General"
        },
        email_addresses: utils.embedded_object(
          {
            email_address: {
              type: "string",
              format: "email",
            },
            description: {
              type: "string",
            },
          },
          ["email_address"],
        ),
        telephones: utils.embedded_object(
             {
                telephone_numbers: {
                   type: "array",
                   items: {
                        type: "object",
                        required: ["type", "label", "telephone_number"],
                        properties: {
                            "type": {
                                type: "string",
                                enum: [
                                    "telephone",
                                    "textphone",
                                    "relay_uk",
                                    "welsh_language"
                                ]
                            },
                            "label": {
                                type: "string",
                            },
                            "telephone_number": {
                                type: "string",
                            }
                        }
                   }
                },
             },
             ["telephone_numbers"],
        ),
        contact_forms: utils.embedded_object(
            {
                url: {
                    type: "string",
                    pattern: "^(?:(?:(?:https?|ftp):)?\\/\\/)(?:\\S+(?::\\S*)?@)?(?:(?!(?:10|127)(?:\\.\\d{1,3}){3})(?!(?:169\\.254|192\\.168)(?:\\.\\d{1,3}){2})(?!172\\.(?:1[6-9]|2\\d|3[0-1])(?:\\.\\d{1,3}){2})(?:[1-9]\\d?|1\\d\\d|2[01]\\d|22[0-3])(?:\\.(?:1?\\d{1,2}|2[0-4]\\d|25[0-5])){2}(?:\\.(?:[1-9]\\d?|1\\d\\d|2[0-4]\\d|25[0-4]))|(?:(?:[a-z0-9\\u00a1-\\uffff][a-z0-9\\u00a1-\\uffff_-]{0,62})?[a-z0-9\\u00a1-\\uffff]\\.)+(?:[a-z\\u00a1-\\uffff]{2,}\\.?))(?::\\d{2,5})?(?:[/?#]\\S*)?$",
                },
            },
            ["url"],
        ),
        addresses: utils.embedded_object(
            {
                street_address: {
                    type: "string",
                },
                locality: {
                    type: "string",
                },
                region: {
                    type: "string",
                },
                postal_code: {
                    type: "string",
                },
                country: {
                    type: "string",
                },
            },
            ["street_address", "locality", "postal_code", "country"],
        ),
      },
      required: [ "contact_type" ]
    },
  },
}
