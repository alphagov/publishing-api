(import "shared/default_format.jsonnet") + {
  document_type: "document_collection",
  definitions: (import "shared/definitions/_whitehall.jsonnet") + {
    details: {
      type: "object",
      additionalProperties: false,
      required: [
        "collection_groups",
        "political",
      ],
      properties: {
        body: {
          "$ref": "#/definitions/body",
        },
        collection_groups: {
          description: "The ordered list of collection groups",
          type: "array",
          items: {
            description: "Collection group",
            type: "object",
            additionalProperties: false,
            required: [
              "title",
              "documents",
            ],
            properties: {
              title: {
                type: "string",
              },
              body: {
                "$ref": "#/definitions/body",
              },
              documents: {
                description: "An ordered list of documents in this collection group",
                type: "array",
                items: {
                  "$ref": "#/definitions/guid",
                },
              },
            },
          },
        },
        first_public_at: {
          "$ref": "#/definitions/first_public_at",
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
        change_history: {
          "$ref": "#/definitions/change_history",
        },
        emphasised_organisations: {
          "$ref": "#/definitions/emphasised_organisations",
        },
        brexit_no_deal_notice: {
          "$ref": "#/definitions/brexit_no_deal_notice",
        }
      },
    },
  },
  edition_links: (import "shared/whitehall_edition_links.jsonnet") + {
    documents: "",
  },
  links: (import "shared/base_links.jsonnet") + {
    government: {
      description: "The government associated with this document",
      maxItems: 1,
    },
    related_guides: "",
    related_policies: "",
    related_mainstream_content: "",
    documents: "",
  },
}
