# Stats on the numbers of editions the change will affect:
#
# specialist_publisher_document_types = %w[aaib_report ai_assurance_portfolio_technique algorithmic_transparency_record animal_disease_case asylum_support_decision business_finance_support_scheme cma_case countryside_stewardship_grant data_ethics_guidance_document design_decision drcf_digital_markets_researche drug_safety_update employment_appeal_tribunal_decision employment_tribunal_decision esi_fund export_health_certificate farming_grant flood_and_coastal_erosion_risk_management_research_report hmrc_contact international_development_fund licence_transaction life_saving_maritime_appliance_service_station maib_report marine_equipment_approved_recommendation marine_notice medical_safety_alert product_safety_alert_report_recall protected_food_drink_name raib_report research_for_development_output residential_property_tribunal_decision service_standard_report sfo_case statutory_instrument tax_tribunal_decision trademark_decision traffic_commissioner_regulatory_decision ukhsa_data_access_approval utaac_decision veterans_support_organisation]
# specialist_publisher_document_types.map { |type| editions = Edition.where(document_type: type, last_edited_at: nil); /
#     [type, editions.count] if editions.count > 0}.compact
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
#  => Adds up to 30.296 (out of 667,461) editions that need to be updated, for a total of 12 (out of 40) document types
#
# For context, all these editions are old, with all but the service_standard_report being prior to the introduction of `last_edited_at`
# to the content items - which was in 2016 - commit a7f49401 - "Add last_edited_at to the ContentItem".
# I was unable to find a specific date for adding it to editions. Either way, the issue seems to be localized to 2016-2017,
# so we can be confident that this won't affect any new editions, and this one-off task won't be needed again in the future.
#
# specialist_publisher_document_types.map { |type| editions = Edition.where(document_type: type, last_edited_at: nil); /
#     [type, editions.min_by(&:created_at).created_at.to_date, editions.max_by(&:created_at).created_at.to_date] if editions.count > 0}.compact
#   =>
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

desc "Update missing last_edited_at timestamp for specialist publisher documents"
task update_missing_last_edited_at_timestamp: :environment do
  specialist_publisher_document_types = %w[aaib_report ai_assurance_portfolio_technique algorithmic_transparency_record animal_disease_case asylum_support_decision business_finance_support_scheme cma_case countryside_stewardship_grant data_ethics_guidance_document design_decision drcf_digital_markets_researche drug_safety_update employment_appeal_tribunal_decision employment_tribunal_decision esi_fund export_health_certificate farming_grant flood_and_coastal_erosion_risk_management_research_report hmrc_contact international_development_fund licence_transaction life_saving_maritime_appliance_service_station maib_report marine_equipment_approved_recommendation marine_notice medical_safety_alert product_safety_alert_report_recall protected_food_drink_name raib_report research_for_development_output residential_property_tribunal_decision service_standard_report sfo_case statutory_instrument tax_tribunal_decision trademark_decision traffic_commissioner_regulatory_decision ukhsa_data_access_approval utaac_decision veterans_support_organisation]

  Edition.where(document_type: specialist_publisher_document_types, last_edited_at: nil).find_each do |edition|
    puts "Updating last_edited_at to #{edition.updated_at} for edition ID: #{edition.id}, type: #{edition.document_type}"

    edition.update_column(:last_edited_at, edition.updated_at)

    puts "Failed to update edition ID: #{edition.id}" if edition.last_edited_at.nil?
  end
end
