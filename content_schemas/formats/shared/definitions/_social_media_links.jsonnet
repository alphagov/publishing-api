{
  type: "array",
  items: {
    type: "object",
    additionalProperties: false,
    required: [
      "service_type",
      "title",
      "href",
    ],
    properties: {
      service_type: {
        type: "string",
        enum: [
          "blog",
          "email",
          "facebook",
          "flickr",
          "foursquare",
          "google-plus",
          "instagram",
          "linkedin",
          "other",
          "pinterest",
          "twitter",
          "youtube",
        ],
      },
      title: {
        type: "string",
      },
      href: {
        type: "string",
        format: "uri",
      },
    },
  },
  description: "A set of links to social media profiles for the object.",
}
