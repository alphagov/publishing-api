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
            subject: {
              type: "string",
            },
            body: {
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
                video_relay_service: {
                  type: "object",
                  properties: {
                    show: {
                      type: "boolean",
                      default: false,
                    },
                    prefix: {
                      type: "string",
                      default: "[Relay UK](https://www.relayuk.bt.com) (if you cannot hear or speak on the phone): 18001 then"
                    },
                    telephone_number: {
                      type: "string",
                    },
                  }
                },
                call_charges: {
                  type: "object",
                  properties: {
                    show_call_charges_info_url: {
                      type: "boolean",
                      default: false,
                    },
                    label: {
                      type: "string",
                      default: "Find out about call charges",
                    },
                    call_charges_info_url: {
                      type: "string",
                      default: "https://gov.uk/call-charges"
                    }
                  },
                },
                description: {
                    type: "string",
                },
                opening_hours: {
                    type: "array",
                    items: {
                        type: "object",
                        required: [
                            "day_from",
                            "day_to",
                            "time_from",
                            "time_to",
                         ],
                         properties: {
                           day_from: {
                             type: "string",
                           },
                           day_to: {
                             type: "string",
                           },
                           time_from: {
                             type: "string",
                             pattern: "^[0-9]{1,2}:[0-9]{2}AM|PM$",
                           },
                           time_to: {
                             type: "string",
                             pattern: "^[0-9]{1,2}:[0-9]{2}AM|PM$",
                           },
                        }
                    }
                },
                bsl_guidance: {
                    type: "object",
                    properties: {
                        show: {
                            type: "boolean",
                            default: false,
                        },
                        value: {
                            type: "string",
                            default: "British Sign Language (BSL) [video relay service](https://connect.interpreterslive.co.uk/vrs) if you’re on a computer - find out how to [use the service on mobile or tablet](https://www.youtube.com/watch?v=oELNMfAvDxw)",
                        },
                    }
                }
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
                town_or_city: {
                    type: "string",
                },
                state_or_county: {
                    type: "string",
                },
                postal_code: {
                    type: "string",
                },
                country: {
                    type: "string",
                },
                description: {
                    type: "string",
                },
            },
        ),
      },
      required: [ "contact_type" ]
    },
  },
}
