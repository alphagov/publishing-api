{
  type: "object",
  required: [
    "formatted_title",
  ],
  properties: {
    formatted_title: {
      type: "string",
    },
    crest: {
      type: "string",
      enum: [
        "bis",
        "dit",
        "eo",
        "hmrc",
        "ho",
        "mod",
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
