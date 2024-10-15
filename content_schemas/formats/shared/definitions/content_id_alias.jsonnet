{
  content_id_alias: {
    description: "Human-readable alias for a Content ID, used when embedding content. Should only be supplied when updating Content Blocks.",
    type: "string",
  },
  content_id_alias_optional: {
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
