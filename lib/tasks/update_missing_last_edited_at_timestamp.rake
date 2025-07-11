# -----------------------------------------------------------
# Stats on the numbers and types of editions the change will affect:
# -----------------------------------------------------------
# specialist_publisher_document_types = %w[aaib_report ai_assurance_portfolio_technique algorithmic_transparency_record animal_disease_case asylum_support_decision business_finance_support_scheme cma_case countryside_stewardship_grant data_ethics_guidance_document design_decision drcf_digital_markets_research drug_safety_update employment_appeal_tribunal_decision employment_tribunal_decision esi_fund export_health_certificate farming_grant flood_and_coastal_erosion_risk_management_research_report hmrc_contact international_development_fund licence_transaction life_saving_maritime_appliance_service_station maib_report marine_equipment_approved_recommendation marine_notice medical_safety_alert product_safety_alert_report_recall protected_food_drink_name raib_report research_for_development_output residential_property_tribunal_decision service_standard_report sfo_case statutory_instrument tax_tribunal_decision trademark_decision traffic_commissioner_regulatory_decision ukhsa_data_access_approval utaac_decision veterans_support_organisation]
# specialist_publisher_document_types.map { |type| editions = Edition.where(document_type: type, last_edited_at: nil); [type, editions.count] if editions.count > 0}.compact
# [["aaib_report", 19689],
#  ["asylum_support_decision", 81],
#  ["business_finance_support_scheme", 655],
#  ["cma_case", 3611],
#  ["countryside_stewardship_grant", 486],
#  ["drug_safety_update", 792],
#  ["esi_fund", 856],
#  ["international_development_fund", 106],
#  ["maib_report", 2603],
#  ["medical_safety_alert", 717],
#  ["raib_report", 664],
#  ["service_standard_report", 36]]
#
#  -> Adds up to 30.296 (out of 667,461) editions that need to be updated, for a total of 12 (out of 40) document types
#
# For context, all these editions are old, with all but the service_standard_report being prior to the introduction of `last_edited_at`
# to the content items - which was in 2016 - commit a7f49401 - "Add last_edited_at to the ContentItem".
# I was unable to find a specific date for adding it to editions. Either way, the issue seems to be localized to 2016-2017,
# so we can be confident that this won't affect any new editions, and this one-off task won't be needed again in the future.
#
# specialist_publisher_document_types.map { |type| editions = Edition.where(document_type: type, last_edited_at: nil); [type, editions.min_by(&:created_at).created_at.to_date, editions.max_by(&:created_at).created_at.to_date] if editions.count > 0}.compact
# =>
# [["aaib_report", Mon, 29 Feb 2016, Tue, 31 May 2016],
#   ["asylum_support_decision", Fri, 24 Feb 2017, Fri, 24 Feb 2017],
#   ["business_finance_support_scheme", Mon, 20 Mar 2017, Mon, 27 Mar 2017],
#   ["cma_case", Mon, 29 Feb 2016, Fri, 19 May 2017],
#   ["countryside_stewardship_grant", Mon, 29 Feb 2016, Tue, 31 May 2016],
#   ["drug_safety_update", Mon, 29 Feb 2016, Mon, 20 Jun 2016],
#   ["esi_fund", Mon, 29 Feb 2016, Mon, 13 Jun 2016],
#   ["international_development_fund", Mon, 29 Feb 2016, Tue, 31 May 2016],
#   ["maib_report", Mon, 29 Feb 2016, Fri, 17 Feb 2017],
#   ["medical_safety_alert", Mon, 29 Feb 2016, Mon, 20 Jun 2016],
#   ["raib_report", Mon, 29 Feb 2016, Wed, 08 Jun 2016],
#   ["service_standard_report", Tue, 14 Feb 2017, Tue, 14 Feb 2017]]

# -----------------------------------------------------------
# Test run
# -----------------------------------------------------------
# We managed to fix: 19270 editions updated
# That's less than the ~30k we have found originally, but we made sense of them, mostly.
#
# **The query**:
# We adapted the query to look for `schema_name` rather than document type.
# We discovered that we have more `schema_name: "specialist_publisher"` than `document_type` from the known types.
# That's because the initial type array only included current types, whereas more types have existed in the past.
#
#
# Edition.where(schema_name: "specialist_document").count
# => 758656
# publishing-api(prod)> specialist_publisher_document_types = %w[aaib_report ai_assurance_portfolio_technique algorithmic_transparency_record animal_disease_case asylum_support_decision business_finance_support_scheme cma_case countryside_stewardship_grant data_ethics_guidance_document design_decision drcf_digital_markets_research drug_safety_update employment_appeal_tribunal_decision employment_tribunal_decision esi_fund export_health_certificate farming_grant flood_and_coastal_erosion_risk_management_research_report hmrc_contact international_development_fund licence_transaction life_saving_maritime_appliance_service_station maib_report marine_equipment_approved_recommendation marine_notice medical_safety_alert product_safety_alert_report_recall protected_food_drink_name raib_report research_for_development_output residential_property_tribunal_decision service_standard_report sfo_case statutory_instrument tax_tribunal_decision trademark_decision traffic_commissioner_regulatory_decision ukhsa_data_access_approval utaac_decision veterans_support_organisation]
# publishing-api(prod)> Edition.where(document_type: specialist_publisher_document_types).count
# => 668124
# publishing-api(prod)> Edition.where(schema_name: "specialist_document").group(:document_type).count
# =>
#   {"aaib_report"=>44135,
#    "ai_assurance_portfolio_technique"=>178,
#    "algorithmic_transparency_record"=>210,
#    "animal_disease_case"=>1278,
#    "asylum_support_decision"=>472,
#    "business_finance_support_scheme"=>3005,
#    "cma_case"=>19417,
#    "countryside_stewardship_grant"=>4677,
#    "data_ethics_guidance_document"=>74,
#    "design_decision"=>8,
#    "dfid_research_output"=>100743,
#    "drcf_digital_markets_research"=>310,
#    "drug_safety_update"=>3805,
#    "employment_appeal_tribunal_decision"=>7573,
#    "employment_tribunal_decision"=>339669,
#    "esi_fund"=>6436,
#    "export_health_certificate"=>20821,
#    "farming_grant"=>765,
#    "flood_and_coastal_erosion_risk_management_research_report"=>1788,
#    "hmrc_contact"=>288,
#    "international_development_fund"=>1173,
#    "licence_transaction"=>1260,
#    "life_saving_maritime_appliance_service_station"=>120,
#    "maib_report"=>7293,
#    "marine_equipment_approved_recommendation"=>222,
#    "marine_notice"=>1,
#    "medical_safety_alert"=>7191,
#    "oim_project"=>12,
#    "product_safety_alert"=>2,
#    "product_safety_alert_report_recall"=>6824,
#    "protected_food_drink_name"=>11686,
#    "raib_report"=>4421,
#    "research_for_development_output"=>111719,
#    "residential_property_tribunal_decision"=>31660,
#    "service_standard_report"=>1753,
#    "sfo_case"=>72,
#    "specialist_document"=>784,
#    "statutory_instrument"=>2260,
#    "tax_tribunal_decision"=>5988,
#    "traffic_commissioner_regulatory_decision"=>94,
#    "ukhsa_data_access_approval"=>9,
#    "uk_market_conformity_assessment_body"=>928,
#    "utaac_decision"=>6937,
#    "veterans_support_organisation"=>595}
#
#
# We can see here additional `uk_market_conformity_assessment_body`, a rather generic `specialist_document`, `oim_project` and `dfid_research_output`, which we do not maintain in the SP repo anymore.
# On [the Research for development output page](https://www.gov.uk/research-for-development-outputs) it says that there were documents published by the DFID before 2020 - maybe it's these ones.
# Outside of this, we also identified that there are, within the matching `document_type` editions, some that do not have the correct `schema_name`:
#
# Edition.where(document_type: specialist_publisher_document_types).where.not(schema_name: "specialist_document").count
# => 11937
# Edition.where(document_type: specialist_publisher_document_types).where(schema_name: "placeholder_specialist_document").count
# => 11937
#
# All of these are of the `placeholder_specialist_document` schema. They are all superseded:
# Edition.where(schema_name: "placeholder_specialist_document", state: "superseded").count
# => 11937
#
# All in all, it is difficult to make sense of the numbers as there are some editions that match current `document_type`, that don't match the `schema_name`, and the other way around. But the overall ~20k fix suffices to address the issue at hand.

desc "Update missing last_edited_at timestamp for specialist publisher documents"
task update_missing_last_edited_at_timestamp: :environment do
  sql = <<~SQL
    UPDATE editions
    SET last_edited_at = updated_at
    WHERE schema_name = 'specialist_document'
    AND last_edited_at IS NULL
  SQL
  rows_updated = ActiveRecord::Base.connection.update(sql)

  puts "#{rows_updated} editions updated"
end
