(import "shared/default_format.jsonnet") + {
  definitions: {
    local_offices: {
      type: "object",
      additionalProperties: false,
      required: [
        'name',
        'assistance_available',
        'organisations_with_embassy_offices'
      ],
      properties: {
        name: {
          type: "string",
          description: "The name of the world location e.g. Argentina",
        },
        assistance_available: {
          type: "string",
          enum: ["local"],
        },
        organisations_with_embassy_offices: {
          type: "array",
          items: {
            type: "object",
            additionalProperties: false,
            required: [
              'locality',
              'name',
              'path',
            ],
            properties: {
              locality: {
                type: "string",
                description: "The locality of the office as set by Whitehall, e.g. Sydney",
              },
              name: {
                type: "string",
                description: "The name of the worldwide organisation that this office belongs to, e.g. British Embassy Buenos Aires",
              },
              path: {
                type: "string",
                description: "The path to the worldwide organisation that this office belongs to, e.g. /world/organisations/british-embassy-buenos-aires",
              },
            },
          },
        },
      },
    },
    remote_offices: {
      type: "object",
      additionalProperties: false,
      required: [
        'name',
        'assistance_available',
        'remote_office',
      ],
      properties: {
        name: {
          type: "string",
          description: "The name of the world location e.g. Argentina",
        },
        assistance_available: {
          type: "string",
          enum: ["remote"],
        },
        remote_office: {
          type: "object",
          required: [
            'name',
            'country',
            'path',
          ],
          properties: {
            name: {
              type: "string",
              description: "The name of the worldwide organisation that this office belongs to, e.g. British Embassy Kabul",
            },
            country: {
              type: "string",
              description: "The remote country that this office is located in, e.g. Qatar",
            },
            path: {
              type: "string",
              description: "The path to the worldwide organisation that this office belongs to, e.g. /world/organisations/british-embassy-kabul",
            },
          },
        },
      },
    },
    no_offices: {
      type: "object",
      additionalProperties: false,
      required: [
        'name',
        'assistance_available',
      ],
      properties: {
        name: {
          type: "string",
          description: "The name of the world location e.g. Anguilla",
        },
        assistance_available: {
          type: "string",
          enum: ["none"],
        },
      },
    },
    details: {
      type: "object",
      additionalProperties: false,
      required: [
        "world_locations"
      ],
      properties: {
        world_locations: {
          type: "array",
          items: {
            oneOf: [
              { "$ref": "#/definitions/local_offices" },
              { "$ref": "#/definitions/remote_offices" },
              { "$ref": "#/definitions/no_offices" }
            ],
          },
        },
      },
    },
  },
}
