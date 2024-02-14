{
  type: "object",
  additionalProperties: false,
  properties: {
    access_and_opening_times: {
      type: [
        "string",
        "null",
      ],
      description: "The access and opening times for this Worldwide Office.",
    },
    contact_content_id: {
      "$ref": "#/definitions/guid",
    },
    services: {
      type: "array",
      uniqueItems: true,
      items: {
        type: "object",
        additionalProperties: false,
        properties: {
          title: {
            type: [
              "string",
              "null",
            ],
            description: "The name of the service provided by this Worldwide Office.",
          },
          type: {
            type: [
              "string",
              "null",
            ],
            description: "The type of service provided by this Worldwide Office.",
          }
        }
      }
    },
    slug: {
      type: "string",
      format: "uri",
    },
    title: {
      type: "string",
    },
    type: {
      type: [
        "string",
        "null",
      ],
      description: "The type of Worldwide Office.",
    },
  }
}
