(import "shared/default_format.jsonnet") + {
  document_type: [
    "about",
    "about_our_services",
    "access_and_opening",
    "accessible_documents_policy",
    "complaints_procedure",
    "equality_and_diversity",
    "media_enquiries",
    "membership",
    "modern_slavery_statement",
    "our_energy_use",
    "our_governance",
    "personal_information_charter",
    "petitions_and_campaigns",
    "procurement",
    "publication_scheme",
    "recruitment",
    "research",
    "social_media_use",
    "staff_update",
    "statistics",
    "terms_of_reference",
    "welsh_language_scheme"
  ],
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      required: [
        "body",
        "organisation",
      ],
      properties: {
        attachments: {
          description: "An ordered list of asset links",
          type: "array",
          items: {
            "$ref": "#/definitions/file_attachment_asset",
          },
        },
        body: {
          "$ref": "#/definitions/body",
        },
        change_history: {
          "$ref": "#/definitions/change_history",
        },
        corporate_information_groups: {
          description: "Groups of corporate information to display on about pages",
          "$ref": "#/definitions/grouped_lists_of_links",
        },
        organisation: {
          description: "A single organisation that is the subject of this corporate information page",
          "$ref": "#/definitions/guid",
        },
        tags: {
          "$ref": "#/definitions/tags",
        },
      },
    },
  },
  edition_links: {
    corporate_information_pages: "",
    government: {
      description: "The government associated with this document",
      maxItems: 1,
    },
    organisations: "All organisations linked to this content item. This should include lead organisations.",
    parent: {
      description: "The parent content item.",
      maxItems: 1,
    },
    primary_publishing_organisation: {
      description: "The organisation that published the page. Corresponds to the first of the 'Lead organisations' in Whitehall, and is empty for all other publishing applications.",
      maxItems: 1,
    },
    original_primary_publishing_organisation: "The organisation that published the original version of the page. Corresponds to the first of the 'Lead organisations' in Whitehall for the first edition, and is empty for all other publishing applications.",
  },
  links: (import "shared/base_links.jsonnet") + {
    corporate_information_pages: "",
    government: {
      description: "The government associated with this document",
      maxItems: 1,
    },
  },
}
