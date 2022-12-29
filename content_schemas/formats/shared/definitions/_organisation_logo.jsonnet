{
  type: "object",
  properties: {
    formatted_title: {
      type: "string",
    },
    crest: {
      type: [
        "string",
        "null",
      ],
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
        null,
      ],
    },
    image: {
      "$ref": "#/definitions/image",
    },
  },
  description: "The organisation's logo, including the logo image and formatted name.",
}
