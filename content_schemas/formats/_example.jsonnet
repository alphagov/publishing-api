// Example Format
// This file explains the syntax of a format and the options you can use

// You can import the default format to inherit most options and then you don't
// need to repeat most of the contents of this file
(import "shared/default_format.jsonnet") + {
  // You can define which document types can be used with this schema
  document_type: ["example", "different_one"],

  // Most formats require a base_path, but they are optional in some and not
  // present at all in others. Without a base_path a format doesn't get
  // represented in the content store.
  base_path: "required",

  // A format with a base_path is most likely going to have routes. The
  // exception is for a format that allows redirects
  // The Publishing API does not allow routes and redirects
  routes: "required",
  redirects: "forbidden",

  title: "required",
  description: "optional",

  // There are formats such as gone/redirects where they're not rendered by an
  // an app
  rendering_app: "required",

  // Normally formats will require details as that holds the key data about the
  // format
  details: "required",

  // The definitions block is used to define the rules behind individual fields
  // in the schema. It can be used to customise what rules are applied in a
  // schema.
  // For example you could define a format that a title must follow for instance.
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      required: ["foo"],
      properties: {
        foo: { "$ref": "#/definitions/foo" },
        bar: { type: "string" },
      },
    },
    // This is the definitions referenced in details
    foo: { type: "string" },
  },

  // We can merged some imported default links
  edition_links: (import "base_edition_links.jsonnet") + {
    a_link: "Description about this link",
    a_required_link: {
      description: "This link is required",
      required: true,
      minItems: 1,
      maxItems: 4,
    },
    // we can define a link as null to remove it from the imported ones
    link_we_dont_want: null,
  },

  // We use the same approach for content links, however we are not allowed
  // required ones as this doesn't work with the Publishing API PATCH approach
  // to setting links
  links: import "base_links.jsonnet",
}
