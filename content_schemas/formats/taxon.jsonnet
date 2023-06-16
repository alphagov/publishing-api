(import "shared/default_format.jsonnet") + {
  document_type: "taxon",
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      properties: {
        internal_name: {
          "$ref": "#/definitions/taxonomy_internal_name",
        },
        notes_for_editors: {
          type: "string",
          description: "Usage notes for editors when tagging content to a taxon.",
        },
        visible_to_departmental_editors: {
          type: "boolean",
          description: "Should this taxon be made visible to Content Editors in publishing apps? It's currently only a consideration for Root Taxons in a draft state.",
        },
        url_override: {
          "$ref": "#/definitions/taxonomy_url_override",
        },
      },
    },
  },
  edition_links: (import "shared/base_edition_links.jsonnet") + {
    parent_taxons: "The list of taxon parents.",
    associated_taxons: "A list of associated taxons whose children should be included as children of this taxon",
  },
  links: (import "shared/base_links.jsonnet") + {
    parent_taxons: {
      description: "The list of taxon parents (DEPRECATED: use the edition links instead)",
    },
    root_taxon: {
      description: "Set to the root taxon (homepage) if this is a level one taxon.",
    },
  },
}
