(import "shared/default_format.jsonnet") + {
  document_type: [
    "world_index"
  ],

  definitions: (import "shared/definitions/_whitehall.jsonnet") + {
    details: {
      type: "object",
      additionalProperties: false,
      required: [
        "international_delegations",
        "world_locations",
      ],
      properties: {
        body: {
          "$ref": "#/definitions/body",
        },
        international_delegations: {
          type: "array",
          "items": {
            "type": "object",
            "required": [
              "name",
              "slug",
              "active"
            ],
            "additionalProperties": false,
            "properties": {
              "name": {
                "description": "The name of the international delegation",
                "type": "string"
              },
              "slug": {
                "description": "The slug of the international delegation",
                "type": "string",
              },
              "active": {
                "description": "Whether the location is currently active",
                "type": "boolean",
              }
            }
          },
        },
        world_locations: {
          type: "array",
          "items": {
            "type": "object",
            "required": [
              "name",
              "slug",
              "active"
            ],
            "additionalProperties": false,
            "properties": {
              "name": {
                "description": "The name of the world location",
                "type": "string"
              },
              "slug": {
                "description": "The slug of the world location",
                "type": "string",
              },
              "active": {
                "description": "Whether the location is currently active",
                "type": "boolean",
              }
            }
          },
        },
      },
    },
  },
}
