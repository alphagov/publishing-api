(import "shared/default_format.jsonnet") + {
  definitions: (import "shared/definitions/_specialist_document.jsonnet") + {
    details: {
      type: "object",
      additionalProperties: false,
      required: [
        "body",
        "metadata",
      ],
      properties: {
        body: {
          "$ref": "#/definitions/body_html_and_govspeak",
        },
        attachments: {
          description: "An ordered list of asset links",
          type: "array",
          items: {
            "$ref": "#/definitions/specialist_publisher_attachment_asset",
          },
        },
        metadata: {
          "$ref": "#/definitions/any_metadata",
        },
        max_cache_time: {
          "$ref": "#/definitions/max_cache_time",
        },
        headers: {
          "$ref": "#/definitions/nested_headers",
        },
        change_history: {
          "$ref": "#/definitions/change_history",
        },
        temporary_update_type: {
          type: "boolean",
          description: "Indicates that the user should choose a new update type on the next save.",
        },
      },
    },
  },
  edition_links: {
    finder: {
      required: true,
      description: "The finder for this specialist document.",
      minItems: 1,
      maxItems: 1,
    },
    primary_publishing_organisation: {
      description: "The primary organisation for this document",
    },
    organisations: {
      description: "Associated organisations for this document",
    },
  },
}
