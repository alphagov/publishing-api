module Presenters
  module MigrateExpandedLinks
    extend self

    def document_types
      %w(service_manual_guide service_manual_topic service_manual_service_standard)
    end

  private

    def next_document_types
      %w(html_publication policy topical_event closed_consultation finder
         world_location cma_case unpublishing oral_statement simple_smart_answer
         placeholder_person official local_transaction detailed_guidance
         placeholder_world_location manual_section foi_release social_media_use
         coming_soon placeholder welsh_language_scheme contact
         placeholder_policy_area dfid_research_output national_statistics
         policy_paper topic notice transparency impact_assessment
         open_consultation gone travel_advice_index programme working_group
         medical_safety_alert terms_of_reference special_route
         placeholder_topical_event aaib_report detailed_guide news_article
         statistical_data_set complaints_procedure transaction fatality_notice
         completed_transaction placeholder_document_collection recruitment
         statutory_guidance campaign business_support
         placeholder_business_support_finder specialist_document regulation
         access_and_opening worldwide_organisation corporate_report
         placeholder_ministerial_role case_study email_alert_signup
         financial_releases_index policy_area national about help_page
         placeholder_smart_answer redirect official_statistics video
         ministerial_role correspondence placeholder_calculator
         government_response our_energy_use financial_release raib_report
         press_release topical_event_about_page international_treaty person
         drug_safety_update form independent_report statistics_announcement
         procurement news_story international_development_fund
         personal_information_charter publication_scheme petitions_and_campaigns
         finder_email_signup statistics take_part
         placeholder_worldwide_organisation financial_releases_success
         written_statement about_our_services our_governance esi_fund research
         hmrc_manual map placeholder_organisation document_collection place
         media_enquiries speech guidance decision mainstream_browse_page
         authored_article consultation_outcome membership maib_report answer
         consultation placeholder_licence_finder travel_advice
         financial_releases_campaign promotional staff_update
         equality_and_diversity manual placeholder_working_group taxon
         placeholder_calendar hmrc_manual_section countryside_stewardship_grant
         organisation announcement guide licence financial_releases_geoblocker)
    end
  end
end
