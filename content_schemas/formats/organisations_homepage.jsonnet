(import "shared/default_format.jsonnet") + {
  document_type: "finder",
  definitions: (import "shared/definitions/_whitehall.jsonnet") + {
    details: {
      type: "object",
      additionalProperties: false,
      properties: {
        ordered_executive_offices: {
          "$ref": "#/definitions/summary_organisations",
        },
        ordered_ministerial_departments: {
          "$ref": "#/definitions/summary_organisations",
        },
        ordered_non_ministerial_departments: {
          "$ref": "#/definitions/summary_organisations",
        },
        ordered_agencies_and_other_public_bodies: {
          "$ref": "#/definitions/summary_organisations",
        },
        ordered_high_profile_groups: {
          "$ref": "#/definitions/summary_organisations",
        },
        ordered_public_corporations: {
          "$ref": "#/definitions/summary_organisations",
        },
        ordered_devolved_administrations: {
          "$ref": "#/definitions/summary_organisations",
        },
      },
    },
  },
}
