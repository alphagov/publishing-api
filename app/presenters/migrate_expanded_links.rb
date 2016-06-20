module Presenters
  module MigrateExpandedLinks
    extend self

    def schema_names
      %w(service_manual_guide service_manual_topic service_manual_service_standard)
    end

  private

    def todo
      %w(
        case_study coming_soon contact detailed_guide
        email_alert_signup financial_release
        financial_releases_campaign financial_releases_geoblocker
        financial_releases_index financial_releases_success finder
        finder_email_signup gone hmrc_manual hmrc_manual_section
        html_publication mainstream_browse_page manual
        manual_section policy publication redirect special_route
        specialist_document statistics_announcement take_part taxon
        topic topical_event_about_page travel_advice
        travel_advice_index unpublishing working_group
       )
    end
  end
end
