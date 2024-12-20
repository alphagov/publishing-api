(import "shared/default_format.jsonnet") + {
  document_type: "organisation",
  definitions: (import "shared/definitions/_whitehall.jsonnet") + {
    details: {
      type: "object",
      additionalProperties: false,
      properties: {
        acronym: {
          type: [
            "string",
            "null",
          ],
          description: "The organisation's acronym, if it has one.",
        },
        analytics_identifier: {
          "$ref": "#/definitions/analytics_identifier",
        },
        alternative_format_contact_email: {
          type: [
            "string",
            "null",
          ],
          description: "The organisation's email for requesting an alternative format for attachments",
        },
        body: {
          "$ref": "#/definitions/body",
        },
        change_note: {
          "$ref": "#/definitions/change_note",
        },
        brand: {
          type: [
            "string",
            "null",
          ],
          description: "The organisation's brand class name, which is mapped to a colour in the frontend.",
        },
        foi_exempt: {
          type: "boolean",
          description: "Whether the organisation is exempt from Freedom of Information requests.",
        },
        logo: (import "shared/definitions/_organisation_logo.jsonnet"),
        ordered_corporate_information_pages: {
          type: "array",
          items: {
            type: "object",
            additionalProperties: false,
            required: [
              "title",
              "href",
            ],
            properties: {
              title: {
                type: "string",
              },
              href: {
                type: "string",
              },
            },
          },
          description: "A set of links to corporate information pages to display for the organisation.",
        },
        secondary_corporate_information_pages: {
          type: "string",
          description: "A string containing sentences and links to corporate information pages that are not included in ordered_corporate_information_pages.",
        },
        ordered_featured_links: {
           "$ref": "#/definitions/ordered_featured_links",
        },
        ordered_featured_documents: {
          "$ref": "#/definitions/ordered_featured_documents",
        },
        ordered_promotional_features: {
          type: "array",
          items: {
            type: "object",
            additionalProperties: false,
            required: [
              "title",
              "items",
            ],
            properties: {
              title: {
                type: "string",
              },
              items: {
                type: "array",
                items: {
                  anyOf: [
                    { "$ref": "#/definitions/promotional_feature_item_image" },
                    { "$ref": "#/definitions/promotional_feature_youtube" },
                  ],
                },
              },
            },
          },
          description: "A set of promotional features to display for the organisation. Turn into proper links once organisations are fully migrated.",
        },
        organisation_featuring_priority: {
          type: "string",
          enum: [
            "news",
            "service",
          ],
          description: "Whether to prioritise news or services on the organisation's home page.",
        },
        organisation_govuk_status: {
          type: "object",
          additionalProperties: false,
          required: [
            "status",
          ],
          properties: {
            status: {
              type: "string",
              enum: [
                "changed_name",
                "devolved",
                "exempt",
                "joining",
                "left_gov",
                "live",
                "merged",
                "no_longer_exists",
                "replaced",
                "split",
                "superseded_by_devolved_administration",
                "transitioning",
              ],
            },
            url: {
              type: [
                "string",
                "null",
              ],
            },
            updated_at: {
              type: [
                "string",
                "null",
              ],
              format: "date-time",
            },
          },
          description: "The status of the organisation on GOV.UK.",
        },
        organisation_type: {
          type: "string",
          enum: [
            "adhoc_advisory_group",
            "advisory_ndpb",
            "civil_service",
            "court",
            "devolved_administration",
            "executive_agency",
            "executive_ndpb",
            "executive_office",
            "independent_monitoring_body",
            "ministerial_department",
            "non_ministerial_department",
            "other",
            "public_corporation",
            "special_health_authority",
            "sub_organisation",
            "tribunal",
          ],
          description: "The type of organisation.",
        },
        "organisation_political": {
          "description": "Determines whether content published by this organisation represents governments policies and can be eligible for history mode",
          "type": "boolean"
        },
        social_media_links: (import "shared/definitions/_social_media_links.jsonnet"),
        external_related_links: {
          "$ref": "#/definitions/external_related_links",
        },
        default_news_image: {
          "$ref": "#/definitions/image",
        },
      },
    },
  },
  links: (import "shared/base_links.jsonnet") + {
    ordered_board_members: "Board members primarily for use with Whitehall organisations.",
    ordered_chief_professional_officers: "Chief professional officers primarily for use with Whitehall organisations.",
    ordered_child_organisations: "Child organisations primarily for use with Whitehall organisations.",
    ordered_contacts: "Contact details primarily for use with Whitehall organisations.",
    ordered_foi_contacts: "FoI contact details primarily for use with Whitehall organisations.",
    ordered_featured_policies: "Featured policies primarily for use with Whitehall organisations.",
    ordered_high_profile_groups: "High profile groups primarily for use with Whitehall organisations.",
    ordered_military_personnel: "Military personnel primarily for use with Whitehall organisations.",
    ordered_ministers: "Ministers primarily for use with Whitehall organisations.",
    ordered_parent_organisations: "Parent organisations primarily for use with Whitehall organisations.",
    ordered_roles: "Organisational roles primarily for use with Whitehall organisations.",
    ordered_special_representatives: "Special representatives primarily for use with Whitehall organisations.",
    ordered_successor_organisations: "Successor organisations primarily for use with closed Whitehall organisations.",
    ordered_traffic_commissioners: "Traffic commissioners primarily for use with Whitehall organisations.",
  },
}
