(import "shared/default_format.jsonnet") + {
  document_type: "html_publication",
  definitions: (import "shared/definitions/_whitehall.jsonnet") + {
    details: {
      type: "object",
      additionalProperties: false,
      required: [
        "body",
        "public_timestamp",
        "first_published_version",
        "political",
      ],
      properties: {
        body: {
          "$ref": "#/definitions/body",
        },
        headings: {
          description: "DEPRECATED. A list of headings used to display a contents list. Superceded in https://github.com/alphagov/government-frontend/pull/384",
          type: "string",
        },
        public_timestamp: {
          type: "string",
          format: "date-time",
        },
        first_published_version: {
          type: "boolean",
        },
        isbn: {
          type: "string",
          description: "Identifies the Print ISBN to be displayed when printing an HTML Publication",
        },
        brexit_no_deal_notice: {
          "$ref": "#/definitions/brexit_no_deal_notice",
        },
        political: {
          "$ref": "#/definitions/political",
        },
        national_applicability: {
          "$ref": "#/definitions/national_applicability",
        },
      },
    },
  },
  links: (import "shared/base_links.jsonnet") + {
    government: {
      description: "The government associated with this document",
      maxItems: 1,
    },
  },
  edition_links: (import "shared/base_edition_links.jsonnet") + {
    government: {
      description: "The government associated with this document",
      maxItems: 1,
    },
    organisations: "",
    parent: "",
    primary_publishing_organisation: {
      description: "The organisation that published the page. Corresponds to the first of the 'Lead organisations' in Whitehall, and is empty for all other publishing applications.",
      maxItems: 1,
    },
    original_primary_publishing_organisation: "The organisation that published the original version of the page. Corresponds to the first of the 'Lead organisations' in Whitehall for the first edition, and is empty for all other publishing applications.",
  },
}
