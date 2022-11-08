(import "shared/default_format.jsonnet") + {
  document_type: "local_transaction",
  definitions: {
    devolved_administration_availability: {
      description: "Used to indicate that a particular devolved administration has a different handling process for the service",
      oneOf: [
        {
          type: "object",
          description: "A value that indicates a service is unavailable",
          additionalProperties: false,
          properties: {
            type: { enum: ["unavailable"] }
          },
          required: ["type"],
        },
        {
          type: "object",
          description: "A value that indicates the service is available through an alternative url",
          additionalProperties: false,
          properties: {
            type: { enum: ["devolved_administration_service"] },
            alternative_url: { type: "string", format: "uri" },
          },
          required: ["type", "alternative_url"],
        },
      ],
    },
    details: {
      type: "object",
      additionalProperties: false,
      required: [
        "lgsl_code",
        "service_tiers",
      ],
      properties: {
        lgsl_code: {
          description: "The Local Government Service List code for the local transaction service",
          type: "integer",
        },
        lgil_override: {
          description: "[DEPRECATED]The Local Government Interaction List override code for the local transaction interaction",
          anyOf: [
            {
              type: "integer",
            },
            {
              type: "null",
            },
          ],
        },
        lgil_code: {
          description: "The Local Government Interaction List code for the local transaction interaction",
          anyOf: [
            {
              type: "integer",
            },
            {
              type: "null",
            },
          ],
        },
        service_tiers: {
          description: "List of local government tiers that provide the service",
          type: "array",
          items: {
            type: "string",
          },
        },
        scotland_availability: {
          "$ref": "#/definitions/devolved_administration_availability",
        },
        wales_availability: {
          "$ref": "#/definitions/devolved_administration_availability",
        },
        northern_ireland_availability: {
          "$ref": "#/definitions/devolved_administration_availability",
        },
        introduction: {
          "$ref": "#/definitions/body_html_and_govspeak",
        },
        more_information: {
          "$ref": "#/definitions/body_html_and_govspeak",
        },
        need_to_know: {
          "$ref": "#/definitions/body_html_and_govspeak",
        },
        external_related_links: {
          "$ref": "#/definitions/external_related_links",
        },
      },
    },
  },
}
