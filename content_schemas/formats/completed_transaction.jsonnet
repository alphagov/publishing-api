(import "shared/default_format.jsonnet") + {
  document_type: "completed_transaction",
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      properties: {
        external_related_links: {
          "$ref": "#/definitions/external_related_links",
        },
        promotion: {
          type: "object",
          additionalProperties: false,
          properties: {
            category: {
              enum: [
                "mot_reminder",
                "organ_donor",
                "register_to_vote",
                "electric_vehicle",
              ],
            },
            url: {
              type: "string",
              format: "uri",
            },
            opt_in_url: {
              type: "string",
              format: "uri",
            },
            opt_out_url: {
              type: "string",
              format: "uri",
            },
          },
          oneOf: [
            {
              properties: {
                category: { enum: ["mot_reminder"] }
              },
              required: ["url"]
            },
            {
              properties: {
                category: { enum: ["organ_donor"] }
              },
              required: ["url"]
            },
            {
              properties: {
                category: { enum: ["register_to_vote"] }
              },
              required: ["url"]
            },
            {
              properties: {
                category: { enum: ["electric_vehicle"] }
              },
              required: ["url"]
            },
          ]
        },
      },
    },
  },
}
