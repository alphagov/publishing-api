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
              "active",
              "content_id",
              "name",
              "slug",
              "updated_at"
            ],
            "additionalProperties": false,
            "properties": {
              "active": {
                "description": "Whether the location is currently active",
                "type": "boolean",
              },
              "analytics_identifier": {
                "description": "The analytics identifier for the international delegation",
                "type": "string"
              },
              "content_id": {
                "description": "The content ID for the international delegation",
                "$ref": "#/definitions/guid",
              },
              "iso2": {
                "description": "The two-letter code for the international delegation in ISO2 format",
                "type": [
                  "string",
                  "null",
                ]
              },
              "name": {
                "description": "The name of the international delegation",
                "type": "string"
              },
              "slug": {
                "description": "The slug of the international delegation",
                "type": "string",
              },
              "updated_at": {
                "description": "The timestamp for the last update to the international delegation",
                type: "string",
                format: "date-time",
              }
            }
          },
        },
        world_locations: {
          type: "array",
          "items": {
            "type": "object",
            "required": [
              "active",
              "content_id",
              "name",
              "slug",
              "updated_at"
            ],
            "additionalProperties": false,
            "properties": {
              "active": {
                "description": "Whether the location is currently active",
                "type": "boolean",
              },
              "analytics_identifier": {
                "description": "The analytics identifier for the world location",
                "type": "string"
              },
              "content_id": {
                "description": "The content ID for the world location",
                "$ref": "#/definitions/guid",
              },
              "iso2": {
                "description": "The two-letter code for the world location in ISO2 format",
                "type": [
                  "string",
                  "null",
                ]
              },
              "name": {
                "description": "The name of the world location",
                "type": "string"
              },
              "slug": {
                "description": "The slug of the world location",
                "type": "string",
              },
              "updated_at": {
                "description": "The timestamp for the last update to the world location",
                type: "string",
                format: "date-time",
              }
            }
          },
        },
      },
    },
  },
}
