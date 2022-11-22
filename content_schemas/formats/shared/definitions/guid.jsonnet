{
  guid: {
    type: "string",
    pattern: "^[a-f0-9]{8}-[a-f0-9]{4}-[1-5][a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}$",
  },
  guid_list: {
    type: "array",
    uniqueItems: true,
    items: {
      "$ref": "#/definitions/guid",
    },
  },
  guid_optional: {
    anyOf: [
      {
        "$ref": "#/definitions/guid",
      },
      {
        type: "null",
      },
    ],
  },
}
