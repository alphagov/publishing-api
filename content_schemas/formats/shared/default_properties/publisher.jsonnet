(import "all.jsonnet") + {
  access_limited: {
    "$ref": "#/definitions/access_limited",
  },
  auth_bypass_ids: {
    description: "A list of ids that will allow access to this item for non-authenticated users",
    "$ref": "#/definitions/guid_list",
  },
  bulk_publishing: {
    type: "boolean",
  },
  change_note: {
    type: [
      "null",
      "string",
    ],
  },
  first_published_at: {
    "$ref": "#/definitions/first_published_at",
  },
  last_edited_at: {
    type: "string",
    format: "date-time",
    description: "Last time when the content received a major or minor update.",
  },
  previous_version: {
    type: "string",
  },
  public_updated_at: {
    "$ref": "#/definitions/public_updated_at",
  },
  update_type: {
    "$ref": "#/definitions/update_type",
  },
  cms_entity_ids: {
    type: "array",
    items: {
      type: "string",
    },
  },
}
