{
  any_metadata: {
    type: "object",
    anyOf: [
      {
        "$ref": "#/definitions/aaib_report_metadata",
      },
      {
        "$ref": "#/definitions/ai_assurance_portfolio_technique_metadata",
      },
      {
        "$ref": "#/definitions/algorithmic_transparency_record_metadata",
      },
      {
        "$ref": "#/definitions/animal_disease_case_metadata",
      },
      {
        "$ref": "#/definitions/asylum_support_decision_metadata",
      },
      {
        "$ref": "#/definitions/business_finance_support_scheme_metadata",
      },
      {
        "$ref": "#/definitions/cma_case_metadata",
      },
      {
        "$ref": "#/definitions/countryside_stewardship_grant_metadata",
      },
      {
        "$ref": "#/definitions/drcf_digital_markets_research_metadata",
      },
      {
        "$ref": "#/definitions/drug_safety_update_metadata",
      },
      {
        "$ref": "#/definitions/employment_appeal_tribunal_decision_metadata",
      },
      {
        "$ref": "#/definitions/employment_tribunal_decision_metadata",
      },
      {
        "$ref": "#/definitions/data_ethics_guidance_document_metadata",
      },
      {
        "$ref": "#/definitions/european_structural_investment_fund_metadata",
      },
      {
        "$ref": "#/definitions/export_health_certificate_metadata",
      },
      {
        "$ref": "#/definitions/international_development_fund_metadata",
      },
      {
        "$ref": "#/definitions/farming_grant_metadata",
      },
      {
        "$ref": "#/definitions/flood_and_coastal_erosion_risk_management_research_report",
      },
      {
        "$ref": "#/definitions/hmrc_contact_metadata",
      },
      {
        "$ref": "#/definitions/licence_transaction_metadata",
      },
      {
          "$ref": "#/definitions/life_saving_maritime_appliance_service_station_metadata",
      },
      {
        "$ref": "#/definitions/maib_report_metadata",
      },
      {
        "$ref": "#/definitions/marine_equipment_approved_recommendation_metadata",
      },
      {
        "$ref": "#/definitions/marine_notice_metadata",
      },
      {
        "$ref": "#/definitions/medical_safety_alert_metadata",
      },
      {
        "$ref": "#/definitions/product_safety_alert_report_recall_metadata",
      },
      {
        "$ref": "#/definitions/protected_food_drink_name_metadata",
      },
      {
        "$ref": "#/definitions/raib_report_metadata",
      },
      {
        "$ref": "#/definitions/research_for_development_output_metadata",
      },
      {
        "$ref": "#/definitions/residential_property_tribunal_decision_metadata",
      },
      {
        "$ref": "#/definitions/service_standard_report_metadata",
      },
      {
        "$ref": "#/definitions/sfo_case_metadata",
      },
      {
        "$ref": "#/definitions/statutory_instrument_metadata",
      },
      {
        "$ref": "#/definitions/tax_tribunal_decision_metadata",
      },
      {
        "$ref": "#/definitions/trademark_decision_metadata",
      },
      {
        "$ref": "#/definitions/traffic_commissioner_regulatory_decision_metadata",
      },
      {
        "$ref": "#/definitions/utaac_decision_metadata",
      },
      {
        "$ref": "#/definitions/veterans_support_organisation_metadata",
      },
    ],
  },
  nested_headers: {
    type: "array",
    minItems: 1,
    items: {
      type: "object",
      additionalProperties: false,
      required: [
        "text",
        "level",
        "id",
      ],
      properties: {
        text: {
          type: "string",
        },
        level: {
          type: "integer",
        },
        id: {
          type: "string",
        },
        headers: {
          "$ref": "#/definitions/nested_headers",
        },
      },
    },
  },
  aaib_report_metadata: {
    type: "object",
    additionalProperties: false,
    properties: {
      bulk_published: {
        type: "boolean",
      },
      aircraft_category: {
        type: "array",
        items: {
          type: "string",
        },
      },
      report_type: {
        type: "string",
      },
      date_of_occurrence: {
        type: "string",
        pattern: "^[1-9][0-9]{3}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[0-1])$",
      },
      aircraft_type: {
        type: "string",
      },
      location: {
        type: "string",
      },
      registration: {
        type: "string",
      },
    },
  },
  ai_assurance_portfolio_technique_metadata: {
    type: "object",
    additionalProperties: false,
    properties: {
      bulk_published: {
        type: "boolean",
      },
      use_case: {
        type: "array",
        items: {
          type: "string",
        },
      },
      sector: {
        type: "array",
        items: {
          type: "string",
        },
      },
      principle: {
        type: "array",
        items: {
          type: "string",
        },
      },
      key_function: { 
        type: "array",
        items: {
          type: "string",
        },
      },
      ai_assurance_technique: {
        type: "array",
        items: {
          type: "string",
        },
      },
      assurance_technique_approach: {
        type: "array",
        items: {
          type: "string",
        },
      },
    },
  },
  algorithmic_transparency_record_metadata: {
    type: "object",
    additionalProperties: false,
    properties: {
      algorithmic_transparency_record_organisation: {
        type: "string",
      },
      algorithmic_transparency_record_organisation_type: {
        type: "array",
        items: {
          type: "string",
        },
      },
      algorithmic_transparency_record_function: {
        type: "array",
        items: {
          type: "string",
        },
      },
      algorithmic_transparency_record_capability: {
        type: "array",
        items: {
          type: "string",
        },
      },
      algorithmic_transparency_record_task: {
        type: "string",
      },
      algorithmic_transparency_record_phase: {
        type: "string",
      },
      algorithmic_transparency_record_region: {
        type: "array",
        items: {
          type: "string",
        },
      },
      algorithmic_transparency_record_date_published: {
        type: "string",
        pattern: "^[1-9][0-9]{3}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[0-1])$",
      },
      algorithmic_transparency_record_atrs_version: {
        type: "string",
      },
      algorithmic_transparency_record_other_tags: {
        type: "string",
      },
    },
  },
  animal_disease_case_metadata: {
    type: "object",
    additionalProperties: false,
    properties: {
      bulk_published: {
        type: "boolean",
      },
      disease_type: {
        type: "array",
        items: {
          type: "string",
        }
      },
      zone_restriction: {
        type: "string",
      },
      zone_type: {
        type: "array",
        items: {
          type: "string",
        }
      },
      virus_strain: {
        type: "string"
      },
      disease_case_opened_date: {
        type: "string",
        pattern: "^[1-9][0-9]{3}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[0-1])$",
      },
      disease_case_closed_date: {
        type: "string",
        pattern: "^[1-9][0-9]{3}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[0-1])$",
      },
    },
  },
  asylum_support_decision_metadata: {
    type: "object",
    additionalProperties: false,
    properties: {
      bulk_published: {
        type: "boolean",
      },
      tribunal_decision_judges: {
        type: "array",
        items: {
          type: "string",
        },
      },
      tribunal_decision_category: {
        type: "string",
      },
      tribunal_decision_categories: {
        type: "array",
        items: {
          type: "string",
        },
      },
      tribunal_decision_sub_category: {
        type: "string",
      },
      tribunal_decision_sub_categories: {
        type: "array",
        items: {
          type: "string",
        },
      },
      tribunal_decision_landmark: {
        type: "string",
      },
      tribunal_decision_reference_number: {
        type: "string",
      },
      tribunal_decision_decision_date: {
        type: "string",
        pattern: "^[1-9][0-9]{3}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[0-1])$",
      },
      hidden_indexable_content: {
        type: "string",
      },
    },
  },
  business_finance_support_scheme_metadata: {
    type: "object",
    additionalProperties: false,
    properties: {
      bulk_published: {
        type: "boolean",
      },
      business_sizes: {
        type: "array",
        items: {
          type: "string",
        },
      },
      business_stages: {
        type: "array",
        items: {
          type: "string",
        },
      },
      continuation_link: {
        type: "string",
      },
      industries: {
        type: "array",
        items: {
          type: "string",
        },
      },
      regions: {
        type: "array",
        items: {
          type: "string",
        },
      },
      types_of_support: {
        type: "array",
        items: {
          type: "string",
        },
      },
      will_continue_on: {
        oneOf: [
          {
            type: "string",
          },
          {
            type: "null",
          },
        ],
      },
    },
  },
  cma_case_metadata: {
    type: "object",
    additionalProperties: false,
    properties: {
      bulk_published: {
        type: "boolean",
      },
      case_type: {
        type: "string",
      },
      case_state: {
        type: "string",
      },
      market_sector: {
        type: "array",
        items: {
          type: "string",
        },
      },
      outcome_type: {
        type: "string",
      },
      opened_date: {
        type: "string",
        pattern: "^[1-9][0-9]{3}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[0-1])$",
      },
      closed_date: {
        type: "string",
        pattern: "^[1-9][0-9]{3}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[0-1])$",
      },
    },
  },
  countryside_stewardship_grant_metadata: {
    type: "object",
    additionalProperties: false,
    properties: {
      bulk_published: {
        type: "boolean",
      },
      grant_type: {
        type: "string",
      },
      land_use: {
        type: "array",
        items: {
          type: "string",
        },
      },
      tiers_or_standalone_items: {
        type: "array",
        items: {
          type: "string",
        },
      },
      funding_amount: {
        type: "array",
        items: {
          type: "string",
        },
      },
    },
  },
  data_ethics_guidance_document_metadata: {
    type: "object",
    additionalProperties: false,
    properties: {
      bulk_published: {
        type: "boolean",
      },
      data_ethics_guidance_document_ethical_theme: {
        type: "array",
        items: {
          type: "string",
        },
      },
      data_ethics_guidance_document_organisation_alias: {
        type: "array",
        items: {
          type: "string",
        },
      },
      data_ethics_guidance_document_project_phase: {
        type: "array",
        items: {
          type: "string",
        },
      },
      data_ethics_guidance_document_technology_area: {
        type: "array",
        items: {
          type: "string",
        },
      },
    },
  },
  drcf_digital_markets_research_metadata: {
    type: "object",
    additionalProperties: false,
    properties: {
      bulk_published: {
        type: "boolean",
      },
      digital_market_research_category: {
        type: "string",
      },
      digital_market_research_publisher: {
        type: "array",
        items: {
          type: "string",
        },
      },
      digital_market_research_area: {
        type: "array",
        items: {
          type: "string",
        },
      },
      digital_market_research_topic: {
        type: "array",
        items: {
          type: "string",
        },
      },
      digital_market_research_publish_date: {
        type: "string",
        pattern: "^[1-9][0-9]{3}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[0-1])$",
      },
    },
  },
  drug_safety_update_metadata: {
    type: "object",
    additionalProperties: false,
    properties: {
      bulk_published: {
        type: "boolean",
      },
      therapeutic_area: {
        type: "array",
        items: {
          type: "string",
        },
      },
      first_published_at: {
        type: "string",
        pattern: "^[1-9][0-9]{3}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[0-1])$",
      },
    },
  },
  employment_appeal_tribunal_decision_metadata: {
    type: "object",
    additionalProperties: false,
    properties: {
      bulk_published: {
        type: "boolean",
      },
      hidden_indexable_content: {
        type: "string",
      },
      tribunal_decision_categories: {
        type: "array",
        items: {
          type: "string",
        },
      },
      tribunal_decision_sub_categories: {
        type: "array",
        items: {
          type: "string",
        },
      },
      tribunal_decision_landmark: {
        type: "string",
      },
      tribunal_decision_decision_date: {
        type: "string",
        pattern: "^[1-9][0-9]{3}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[0-1])$",
      },
    },
  },
  employment_tribunal_decision_metadata: {
    type: "object",
    additionalProperties: false,
    properties: {
      bulk_published: {
        type: "boolean",
      },
      tribunal_decision_country: {
        type: "string",
      },
      tribunal_decision_categories: {
        type: "array",
        items: {
          type: "string",
        },
      },
      tribunal_decision_decision_date: {
        type: "string",
        pattern: "^[1-9][0-9]{3}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[0-1])$",
      },
      hidden_indexable_content: {
        type: "string",
      },
    },
  },
  european_structural_investment_fund_metadata: {
    type: "object",
    additionalProperties: false,
    properties: {
      bulk_published: {
        type: "boolean",
      },
      fund_state: {
        type: "string",
      },
      fund_type: {
        type: "array",
        items: {
          type: "string",
        },
      },
      location: {
        type: "array",
        items: {
          type: "string",
        },
      },
      funding_source: {
        type: "array",
        items: {
          type: "string",
        },
      },
      closing_date: {
        type: "string",
        pattern: "^[1-9][0-9]{3}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[0-1])$",
      },
    },
  },
  export_health_certificate_metadata: {
    type: "object",
    additionalProperties: false,
    properties: {
      certificate_status: {
        type: "string",
      },
      commodity_type: {
        type: "string",
      },
      destination_country: {
        type: "array",
        items: {
          type: "string",
        },
      },
    },
  },
  farming_grant_metadata: {
    type: "object",
    additionalProperties: false,
    properties: {
      bulk_published: {
        type: "boolean",
      },
      areas_of_interest: {
        type: "array",
        items: {
          type: "string",
        }
      },
      land_types: {
        type: "array",
        items: {
          type: "string",
        }
      },
      payment_types: {
        type: "array",
        items: {
          type: "string",
        },
      },
    },
  },
  flood_and_coastal_erosion_risk_management_research_report: {
    type: "object",
    additionalProperties: false,
    properties: {
      project_code: {
        type: "string",
      },
      flood_and_coastal_erosion_category: {
        type: "string",
      },
      topics: {
        type: "array",
        items: {
          type: "string",
        },
      },
      project_status: {
        type: "string",
      },
      date_of_start: {
        type: "string",
        pattern: "^[1-9][0-9]{3}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[0-1])$",
      },
      date_of_completion: {
        type: "string",
        pattern: "^[1-9][0-9]{3}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[0-1])$",
      },
    },
  },
  hmrc_contact_metadata: {
    type: "object",
    additionalProperties: false,
    properties: {
      topics: {
        type: "array",
        items: {
          type: "string",
        },
      },
    },
  },
  international_development_fund_metadata: {
    type: "object",
    additionalProperties: false,
    properties: {
      bulk_published: {
        type: "boolean",
      },
      fund_state: {
        type: "string",
      },
      location: {
        type: "array",
        items: {
          type: "string",
        },
      },
      development_sector: {
        type: "array",
        items: {
          type: "string",
        },
      },
      eligible_entities: {
        type: "array",
        items: {
          type: "string",
        },
      },
      value_of_funding: {
        type: "array",
        items: {
          type: "string",
        },
      },
    },
  },
  licence_transaction_metadata: {
    type: "object",
    additionalProperties: false,
    properties: {
      bulk_published: {
        type: "boolean",
      },
      licence_transaction_location: {
        type: "array",
        items: {
          type: "string",
        },
      },
      licence_transaction_industry: {
        type: "array",
        items: {
          type: "string",
        },
      },
      licence_transaction_will_continue_on: {
        "$ref": "#/definitions/will_continue_on",
      },
      licence_transaction_continuation_link: {
        type: "string",
        format: "uri",
      },
      licence_transaction_licence_identifier: {
        type: "string",
      },
    },
  },
  life_saving_maritime_appliance_service_station_metadata: {
    type: "object",
    additionalProperties: false,
    properties: {
      bulk_published: {
        type: "boolean",
      },
      life_saving_maritime_appliance_service_station_regions: {
        type: "array",
        items: {
          type: "string",
        },
      },
      life_saving_maritime_appliance_manufacturer: {
        type: "array",
        items: {
          type: "string",
        },
      },
      life_saving_maritime_appliance_type: {
        type: "array",
        items: {
          type: "string",
        },
      },
    },
  },
  maib_report_metadata: {
    type: "object",
    additionalProperties: false,
    properties: {
      bulk_published: {
        type: "boolean",
      },
      vessel_type: {
        type: "array",
        items: {
          type: "string",
        },
      },
      report_type: {
        type: "string",
      },
      date_of_occurrence: {
        type: "string",
        pattern: "^[1-9][0-9]{3}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[0-1])$",
      },
    },
  },
  marine_equipment_approved_recommendation_metadata: {
    type: "object",
    additionalProperties: false,
    properties: {
      bulk_published: {
        type: "boolean",
      },
      category: {
        type: "array",
        items: {
          type: "string",
        },
      },
      year_adopted: {
        type: "string",
        pattern: "^[1-9][0-9]{3}$",
      },
      reference_number: {
        type: "string",
      },
      keyword: {
        type: "string"
      },
    },
  },
  marine_notice_metadata: {
    type: "object",
    additionalProperties: false,
    properties: {
      bulk_published: {
        type: "boolean",
      },
      marine_notice_type: {
        type: "string",
      },
      marine_notice_vessel_type: {
        type: "array",
        items: {
          type: "string",
        },
      },
      marine_notice_topic: {
        type: "array",
        items: {
          type: "string",
        },
      },
      issued_date: {
        type: "string",
        pattern: "^[1-9][0-9]{3}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[0-1])$",
      },
    },
  },
  medical_safety_alert_metadata: {
    type: "object",
    additionalProperties: false,
    properties: {
      bulk_published: {
        type: "boolean",
      },
      alert_type: {
        type: "string",
      },
      medical_specialism: {
        type: "array",
        items: {
          type: "string",
        },
      },
      issued_date: {
        type: "string",
        pattern: "^[1-9][0-9]{3}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[0-1])$",
      },
    },
  },
  product_safety_alert_report_recall_metadata: {
    type: "object",
    additionalProperties: false,
    properties: {
      bulk_published: {
        type: "boolean",
      },
      product_alert_type: {
        type: "string",
      },
      product_risk_level: {
        type: "string",
      },
      product_category: {
        type: "string",
      },
      product_measure_type: {
        type: "array",
        items: {
          type: "string",
        },
      },
      product_recall_alert_date: {
        type: "string",
        pattern: "^[1-9][0-9]{3}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[0-1])$",
      },
    },
  },
  protected_food_drink_name_metadata: {
    type: "object",
    additionalProperties: false,
    properties: {
      registered_name: {
        type: "string"
      },
      register: {
        type: "string",
      },
      status: {
        type: "string",
      },
      class_category: {
        type: "array",
        items: {
          type: "string",
        },
      },
      protection_type: {
        type: "string",
      },
      reason_for_protection: {
        type: "string",
      },
      country_of_origin: {
        type: "array",
        items: {
          type: "string",
        },
      },
      traditional_term_grapevine_product_category: {
        type: "array",
        items: {
          type: "string",
        },
      },
      traditional_term_type: {
        type: "string",
      },
      traditional_term_language: {
        type: "string",
      },
      date_application: {
        type: "string",
        pattern: "^[1-9][0-9]{3}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[0-1])$"
      },
      date_registration: {
        type: "string",
        pattern: "^[1-9][0-9]{3}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[0-1])$"
      },
      time_registration: {
        type: "string",
        pattern: "^(0[0-9]|1[0-9]|2[0-3]):[0-5][0-9]$"
      },
      date_registration_eu: {
        type: "string",
        pattern: "^[1-9][0-9]{3}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[0-1])$"
      },
      internal_notes: {
        type: "string"
      }
    }
  },
  raib_report_metadata: {
    type: "object",
    additionalProperties: false,
    properties: {
      bulk_published: {
        type: "boolean",
      },
      railway_type: {
        type: "array",
        items: {
          type: "string",
        },
      },
      report_type: {
        type: "string",
      },
      date_of_occurrence: {
        type: "string",
        pattern: "^[1-9][0-9]{3}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[0-1])$",
      },
    },
  },
  research_for_development_output_metadata: {
    type: "object",
    additionalProperties: false,
    properties: {
      bulk_published: {
        type: "boolean",
      },
      review_status: {
        type: "string",
      },
      country: {
        type: "array",
        items: {
          type: "string",
        },
      },
      authors: {
        type: "array",
        items: {
          type: "string",
        },
      },
      first_published_at: {
        type: "string",
        pattern: "^[1-9][0-9]{3}[-/](0[1-9]|1[0-2])[-/](0[1-9]|[12][0-9]|3[0-1])$",
      },
      theme: {
        type: "array",
        items: {
          type: "string",
        },
      },
      research_document_type: {
        type: "string",
      },
    },
  },
  residential_property_tribunal_decision_metadata: {
    type: "object",
    additionalProperties: false,
    properties: {
      bulk_published: {
        type: "boolean",
      },
      tribunal_decision_category: {
        type: "string",
      },
      tribunal_decision_sub_category: {
        type: "string",
      },
      tribunal_decision_decision_date: {
        type: "string",
        pattern: "^[1-9][0-9]{3}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[0-1])$",
      },
      hidden_indexable_content: {
        type: "string",
      },
    },
  },
  service_standard_report_metadata: {
    type: "object",
    additionalProperties: false,
    properties: {
      bulk_published: {
        type: "boolean",
      },
      assessment_date: {
        type: "string",
        pattern: "^[1-9][0-9]{3}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[0-1])$",
      },
      result: {
        type: "string",
      },
      stage: {
        type: "string",
      },
      service_provider: {
        "$ref": "#/definitions/guid",
      },
    },
  },
  sfo_case_metadata: {
    type: "object",
    additionalProperties: false,
    properties: {
      sfo_case_state: {
        type: "string",
      },
      sfo_case_date_announced: {
        type: "string",
        pattern: "^[1-9][0-9]{3}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[0-1])$",
      },
    },
  },
  statutory_instrument_metadata: {
    type: "object",
    additionalProperties: false,
    properties: {
      laid_date: {
        type: "string",
        pattern: "^[1-9][0-9]{3}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[0-1])$",
      },
      sift_end_date: {
        type: "string",
        pattern: "^[1-9][0-9]{3}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[0-1])$",
      },
      sifting_status: {
        type: "string",
      },
      withdrawn_date: {
        type: "string",
        pattern: "^[1-9][0-9]{3}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[0-1])$",
      },
      subject: {
        type: "array",
        items: {
          type: "string",
        },
      },
    },
  },
  tax_tribunal_decision_metadata: {
    type: "object",
    additionalProperties: false,
    properties: {
      bulk_published: {
        type: "boolean",
      },
      tribunal_decision_category: {
        type: "string",
      },
      tribunal_decision_decision_date: {
        type: "string",
        pattern: "^[1-9][0-9]{3}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[0-1])$",
      },
      hidden_indexable_content: {
        type: "string",
      },
    },
  },
  trademark_decision_metadata: {
    type: "object",
    additionalProperties: false,
    properties: {
      bulk_published: {
        type: "boolean",
      },
      trademark_decision_british_library_number: {
        type: "string",
      },
      trademark_decision_type_of_hearing: {
        type: "string",
      },
      trademark_decision_mark: {
        type: "string",
      },
      trademark_decision_class: {
        type: "string",
      },
      trademark_decision_date: {
        type: "string",
        pattern: "^[1-9][0-9]{3}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[0-1])$",
      },
      trademark_decision_appointed_person_hearing_officer: {
        type: "string",
      },
      trademark_decision_person_or_company_involved: {
        type: "string",
      },
      trademark_decision_grounds_section: {
        type: "array",
        items: {
          type: "string",
        },
      },
      trademark_decision_grounds_sub_section: {
        type: "array",
        items: {
          type: "string",
        },
      },
    },
  },
  traffic_commissioner_regulatory_decision_metadata: {
    type: "object",
    additionalProperties: false,
    properties: {
      "decision_subject": {
        type: "array",
        items: {
          type: "string",
        },
      },
      regions: {
        type: "array",
        items: {
          type: "string",
        },
      },
      "case_type": {
        type: "array",
        items: {
          type: "string",
        },
      },
      "outcome_type": {
        type: "array",
        items: {
          type: "string",
        },
      },
      first_published_at: {
        type: "string",
        pattern: "^[1-9][0-9]{3}[-/](0[1-9]|1[0-2])[-/](0[1-9]|[12][0-9]|3[0-1])$",
      },
    },
  },
  utaac_decision_metadata: {
    type: "object",
    additionalProperties: false,
    properties: {
      bulk_published: {
        type: "boolean",
      },
      tribunal_decision_judges: {
        type: "array",
        items: {
          type: "string",
        },
      },
      tribunal_decision_categories: {
        type: "array",
        items: {
          type: "string",
        },
      },
      tribunal_decision_sub_categories: {
        type: "array",
        items: {
          type: "string",
        },
      },
      tribunal_decision_decision_date: {
        type: "string",
        pattern: "^[1-9][0-9]{3}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[0-1])$",
      },
      hidden_indexable_content: {
        type: "string",
      },
    },
  },
  veterans_support_organisation_metadata: {
    type: "object",
    additionalProperties: false,
    properties: {
      bulk_published: {
        type: "boolean",
      },
      veterans_support_organisation_health_and_social_care: {
        type: "array",
        items: {
          type: "string",
        },
      },
      veterans_support_organisation_finance: {
        type: "array",
        items: {
          type: "string",
        },
      },
      veterans_support_organisation_legal_and_justice: {
        type: "array",
        items: {
          type: "string",
        },
      },
      veterans_support_organisation_employment_education_and_training: {
        type: "array",
        items: {
          type: "string",
        },
      },
      veterans_support_organisation_housing: {
        type: "array",
        items: {
          type: "string",
        },
      },
      veterans_support_organisation_families_and_children: {
        type: "array",
        items: {
          type: "string",
        },
      },
      veterans_support_organisation_community_and_social: {
        type: "array",
        items: {
          type: "string",
        },
      },
      veterans_support_organisation_region_england: {
        type: "array",
        items: {
          type: "string",
        },
      },
      veterans_support_organisation_region_northern_ireland: {
        type: "array",
        items: {
          type: "string",
        },
      },
      veterans_support_organisation_region_scotland: {
        type: "array",
        items: {
          type: "string",
        },
      },
      veterans_support_organisation_region_wales: {
        type: "array",
        items: {
          type: "string",
        },
      },
    },
  },
}
