{
  instructions_to_publishers: {
    description: "Internal message to add context to a Content Block. Should only be supplied for Content Blocks.",
    type: "string",
  },
  instructions_to_publishers_optional: {
    anyOf: [
      {
        "$ref": "#/definitions/content_id_alias",
      },
      {
        type: "null",
      },
    ],
  },
}
