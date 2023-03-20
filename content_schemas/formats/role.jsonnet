(import "shared/default_format.jsonnet") + {
  document_type: [
    "ambassador_role",
    "board_member_role",
    "chief_professional_officer_role",
    "chief_scientific_advisor_role",
    "chief_scientific_officer_role",
    "deputy_head_of_mission_role",
    "governor_role",
    "high_commissioner_role",
    "military_role",
    "ministerial_role",
    "special_representative_role",
    "traffic_commissioner_role",
    "worldwide_office_staff_role",
  ],
  base_path: "optional",
  routes: "optional",
  definitions: {
    details: {
      type: "object",
      additionalProperties: false,
      properties: {
        body: {
          "$ref": "#/definitions/body_html_and_govspeak",
        },
        attends_cabinet_type: {
          type: [
            "string",
            "null",
          ],
          enum: [
            "Attends Cabinet",
            "Attends Cabinet when Ministerial responsibilities are on the agenda",
            null,
          ],
        },
        role_payment_type: {
          type: [
            "string",
            "null",
          ],
        },
        supports_historical_accounts: {
          type: "boolean",
        },
        seniority: {
          type: "integer",
        },
        whip_organisation: {
          type: "object",
          properties: {
            sort_order: {
              type: [
                "integer",
                "null",
              ],
            },
            label: {
              type: [
                "string",
                "null",
              ],
            },
          },
        },
      },
    },
  },
  links: (import "shared/base_links.jsonnet") + {
    ordered_parent_organisations: "Organisations that own this role.",
    ministerial: {
      description: "Link to the ministers index page, present if this is a ministerial role.",
      maxItems: 1,
    },
  },
}
