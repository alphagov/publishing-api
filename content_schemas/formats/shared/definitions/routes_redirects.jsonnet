{
  routes: {
    type: "array",
    minItems: 1,
    items: {
      "$ref": "#/definitions/route",
    },
  },
  routes_optional: {
    type: "array",
    items: {
      ref: "#/definitions/route",
    },
  },
  redirects: {
    type: "array",
    minItems: 1,
    items: {
      "$ref": "#/definitions/redirect_route",
    },
  },
  redirects_optional: {
    type: "array",
    items: {
      "$ref": "#/definitions/redirect_route",
    },
  },
  route: {
    type: "object",
    additionalProperties: false,
    required: [
      "path",
      "type",
    ],
    properties: {
      path: {
        type: "string",
      },
      type: {
        enum: [
          "prefix",
          "exact",
        ],
      },
    },
  },
  redirect_route: {
    type: "object",
    additionalProperties: false,
    required: [
      "path",
      "type",
      "destination",
    ],
    properties: {
      path: {
        "$ref": "#/definitions/absolute_path",
      },
      type: {
        enum: [
          "prefix",
          "exact",
        ],
      },
      destination: { type: "string", format: "uri" },
      segments_mode: {
        enum: [
          "preserve",
          "ignore",
        ],
        description: "For prefix redirects, preserve or ignore the rest of the fullpath. For exact, preserve or ignore the querystring.",
      },
    },
  }
}
