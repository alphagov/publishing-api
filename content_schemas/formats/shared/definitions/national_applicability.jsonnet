{
  nation_applicability: {
    description: "An object specifying the applicability of a particular nation.",
    type: "object",
    additionalProperties: false,
    properties: {
      label: {
        description: "The pretty-printed, translated label for this nation.",
        type: "string",
      },
      alternative_url: {
        description: "An optional alternative URL to link to for more information on this content item pertaining to this nation.",
        type: "string",
      },
      applicable: {
        description: "Whether the content applies to this nation or not.",
        type: "boolean",
      },
    },
  },
  national_applicability: {
    description: "An object specifying the applicable nations for this content item. If it applies to all nations, it should be omitted.",
    type: "object",
    additionalProperties: false,
    properties: {
      england: {
        "$ref": "#/definitions/nation_applicability",
      },
      northern_ireland: {
        "$ref": "#/definitions/nation_applicability",
      },
      scotland: {
        "$ref": "#/definitions/nation_applicability",
      },
      wales: {
        "$ref": "#/definitions/nation_applicability",
      },
    },
  },
}
