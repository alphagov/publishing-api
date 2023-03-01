{
  rendering_app: {
    description: "The application that renders this item.",
    type: "string",
    enum: [
      "account-api",
      "calculators",
      "calendars",
      "collections",
      "content-store",
      "email-alert-frontend",
      "email-campaign-frontend",
      "feedback",
      "finder-frontend",
      "frontend",
      "government-frontend",
      "info-frontend",
      "licencefinder",
      "performanceplatform-big-screen-view",
      "rummager",
      "search-api",
      "smartanswers",
      "spotlight",
      "static",
      "tariff",
      "whitehall-admin",
      "whitehall-frontend",
    ],
  },
  rendering_app_optional: {
    anyOf: [
      {
        "$ref": "#/definitions/rendering_app",
      },
      {
        type: "null",
      },
    ],
  },
}
