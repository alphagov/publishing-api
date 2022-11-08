(import "shared/default_format.jsonnet") + {
  document_type: "statistical_data_set",
  definitions: (import "shared/definitions/_whitehall.jsonnet") + {
    details: {
      type: "object",
      additionalProperties: false,
      required: [
        "body",
        "political",
      ],
      properties: {
        attachments: {
          description: "An ordered list of asset links",
          type: "array",
          items: {
            "$ref": "#/definitions/publication_attachment_asset",
          },
        },
        body: {
          "$ref": "#/definitions/body",
        },
        first_public_at: {
          "$ref": "#/definitions/first_public_at",
        },
        change_history: {
          "$ref": "#/definitions/change_history",
        },
        tags: {
          "$ref": "#/definitions/tags",
        },
        government: {
          "$ref": "#/definitions/government",
        },
        political: {
          "$ref": "#/definitions/political",
        },
        emphasised_organisations: {
          "$ref": "#/definitions/emphasised_organisations",
        },
      },
    },
  },
  links: (import "shared/base_links.jsonnet") + {
    government: "The government associated with this document",
  },
  edition_links: (import "shared/base_edition_links.jsonnet") + {
    organisations: "All organisations linked to this content item. This should include lead organisations.",
    primary_publishing_organisation: {
      description: "The organisation that published the page. Corresponds to the first of the 'Lead organisations' in Whitehall, and is empty for all other publishing applications.",
      maxItems: 1,
    }
  }
}
