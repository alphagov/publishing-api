(import "shared/default_format.jsonnet") + {
  document_type: "fatality_notice",
  definitions: (import "shared/definitions/_whitehall.jsonnet") + {
    details: {
      type: "object",
      additionalProperties: false,
      required: [
        "body",
        "change_history",
        "emphasised_organisations",
        "roll_call_introduction"
      ],
      properties: {
        body: {
          "$ref": "#/definitions/body",
        },
        casualties: {
          type: "array",
          items: {
            type: "string"
          }
        },
        first_public_at: {
          "$ref": "#/definitions/first_public_at",
        },
        change_history: {
          "$ref": "#/definitions/change_history",
        },
        emphasised_organisations: {
          "$ref": "#/definitions/emphasised_organisations",
        },
        roll_call_introduction: {
          type: "string",
        },
      },
    },
  },
  edition_links: (import "shared/base_edition_links.jsonnet") + {
    field_of_operation: {
      maxItems: 1,
      minItems: 1,
    },
    organisations: "All organisations linked to this content item. This should include lead organisations.",
    people: "People that are associated with this document, typically the person part of a role association",
    primary_publishing_organisation: {
      description: "The organisation that published the page. Corresponds to the first of the 'Lead organisations' in Whitehall, and is empty for all other publishing applications.",
      maxItems: 1,
    },
    original_primary_publishing_organisation: "The organisation that published the original version of the page. Corresponds to the first of the 'Lead organisations' in Whitehall for the first edition, and is empty for all other publishing applications.",
    roles: "Government roles that are associated with this document, typically the role part of a role association",
  },
  links: (import "shared/base_links.jsonnet") + {
    field_of_operation: {
      maxItems: 1,
    },
    people: "People that are associated with this document, typically the person part of a role association",
    roles: "Government roles that are associated with this document, typically the role part of a role association",
  },
}
