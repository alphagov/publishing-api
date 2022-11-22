{
  analytics_identifier: {
    "$ref": "#/definitions/analytics_identifier",
  },
  details: {
    "$ref": "#/definitions/details",
  },
  locale: {
    "$ref": "#/definitions/locale",
  },
  need_ids: {
    type: "array",
    items: {
      type: "string",
    },
  },
  phase: {
    description: "The service design phase of this content item - https://www.gov.uk/service-manual/phases",
    type: "string",
    enum: [
      "alpha",
      "beta",
      "live",
    ],
  },
  publishing_app: {
    "$ref": "#/definitions/publishing_app_name",
  },
}
