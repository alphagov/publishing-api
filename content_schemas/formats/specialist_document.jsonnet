(import "shared/default_format.jsonnet") + {
  document_type: [
    "aaib_report",
    "animal_disease_case",
    "asylum_support_decision",
    "business_finance_support_scheme",
    "cma_case",
    "uk_market_conformity_assessment_body",
    "countryside_stewardship_grant",
    "dfid_research_output",
    "drcf_digital_markets_research",
    "drug_safety_update",
    "employment_appeal_tribunal_decision",
    "employment_tribunal_decision",
    "eurovision_winner"
    "esi_fund",
    "export_health_certificate",
    "flood_and_coastal_erosion_risk_management_research_report",
    "international_development_fund",
    "licence_transaction",
    "maib_report",
    "marine_notice",
    "medical_safety_alert",
    "oim_project",
    "product_safety_alert_report_recall",
    "protected_food_drink_name",
    "raib_report",
    "research_for_development_output",
    "residential_property_tribunal_decision",
    "service_standard_report",
    "statutory_instrument",
    "tax_tribunal_decision",
    "traffic_commissioner_regulatory_decision",
    "utaac_decision",
  ],
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
