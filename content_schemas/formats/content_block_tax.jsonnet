local utils = import "shared/utils/content_block_utils.jsonnet";

(import "shared/content_block.jsonnet") + {
  document_type: "content_block_tax",
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      required: ["tax_type"],
      properties: {
        abbreviation: {
          type: "string"
        },
        synonym: {
          type: "string"
        },
        tax_type: {
          type: "string",
          enum: [
            "Tax",
            "Duty",
            "Levy",
            "Surcharge",
            "Repayment",
            "Charge"
          ]
        },
        note: {
          type: "string",
        },
        description: {
          type: "string",
        },
        things_taxed: utils.embedded_object({
          title: {
            type: "string"
          },
          type: {
            type: "string",
            enum: [
                "Entity value",
                "Transaction",
                "Gain",
                "Activity",
                "Income",
                "Asset"
            ]
          },
          rates: {
            type: "array",
            items: {
              type: "object",
              required: ["name", "value"],
              properties: {
                name: {
                  type: "string",
                },
                value: {
                    type: "string",
                },
                bands: {
                    type: "array",
                    items: {
                        type: "object",
                        required: ["name"],
                        properties: {
                            name: {
                                type: "string"
                            },
                            lower_threshold: {
                                type: "object",
                                required: ["value"],
                                properties: {
                                    show: {
                                        type: "boolean",
                                        default: false,
                                    },
                                    value: {
                                        type: "string"
                                    },
                                }
                            },
                            upper_threshold: {
                                type: "object",
                                required: ["value"],
                                properties: {
                                    show: {
                                        type: "boolean",
                                        default: false,
                                    },
                                    value: {
                                        type: "string"
                                    },
                                }
                            }
                        }
                    }
                }
              },
            },
          },
        }, ["title", "type", "rates"])
      },
    },
  },
}
