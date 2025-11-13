{
  type: "object",
  required: [
    "formatted_title",
  ],
  additionalProperties: false,
  properties: {
    formatted_title: {
      type: "string",
    },
    crest: {
      type: "string",
      enum: [
        "bis",
        "custom",
        "dbt",
        "eo",
        "gds",
        "hmrc",
        "ho",
        "mod",
        "no10",
        "no-identity",
        "portcullis",
        "single-identity",
        "so",
        "ukaea",
        "wales",
      ],
    },
    image: {
      "$ref": "#/definitions/image",
    },
  },
  description: "The organisation's logo, including the logo image and formatted name.",
}
