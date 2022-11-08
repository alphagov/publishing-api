{
  external_related_links: {
    type: "array",
    items: {
      "$ref": "#/definitions/external_link",
    },
  },
  external_link: {
    type: "object",
    additionalProperties: false,
    required: [
      "title",
      "url",
    ],
    properties: {
      title: {
        type: "string",
      },
      url: {
        type: "string",
        format: "uri",
      },
    },
  },
  internal_link_without_guid: {
    description: "Links to pages on GOV.UK without a corresponding GUID. eg A filtered list of publications",
    type: "object",
    additionalProperties: false,
    required: [
      "title",
      "path",
    ],
    properties: {
      title: {
        type: "string",
      },
      path: {
        "$ref": "#/definitions/absolute_fullpath",
      },
    },
  },
  internal_or_external_link: {
    anyOf: [
      {
        "$ref": "#/definitions/external_link",
      },
      {
        "$ref": "#/definitions/internal_link_without_guid",
      },
      {
        "$ref": "#/definitions/guid",
      },
    ],
  },
  grouped_lists_of_links: {
    description: "Lists of links with titles in named groups",
    type: "array",
    items: {
      type: "object",
      additionalProperties: false,
      required: [
        "name",
        "contents",
      ],
      properties: {
        name: {
          description: "Title of the group",
          type: "string",
        },
        contents: {
          description: "An ordered list of links, either internal with GUID or external with URL and title",
          type: "array",
          items: {
            "$ref": "#/definitions/internal_or_external_link",
          },
        },
      },
    },
  },
  will_continue_on: {
    description: "Description of the website the adjoining external link will be taking the user to",
    type: "string",
  },
}
