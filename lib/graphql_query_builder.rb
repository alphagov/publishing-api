class GraphqlQueryBuilder
  MAX_LINK_DEPTH = 5

  def initialize(schema_name)
    @schema_name = schema_name
    @content_item = GovukSchemas::RandomExample.for_schema(
      frontend_schema: @schema_name,
      strategy: :one_of_everything,
    )
  end

  def build_query
    parts = [
      "query #{@schema_name}($base_path: String!) {",
      "  edition(base_path: $base_path) {",
      "    ... on #{edition_type_or_subtype} {",
      build_fields(@content_item, indent: 6),
      "    }",
      "  }",
      "}",
    ]

    parts.join("\n")
  end

private

  def build_fields(data, indent: 2, link_path: [])
    fields = data.sort_by(&:first).flat_map do |entry|
      case entry
      in ["withdrawn", *]
        nil
      in [String, {} | []]
        nil
      in ["details" | "withdrawn_notice" => key, Hash => hash]
        [
          "#{key} {",
          hash.map { |hash_key, _| "  #{hash_key}" },
          "}",
        ]
      in ["links", Hash => links]
        [
          "links {",
          links.map { |link_key, array| build_links_query(link_path + [link_key.to_sym], array) }.compact,
          "}",
        ]
      in [String => key, String | Numeric | true | false | nil]
        key
      end
    end
    fields.compact.join("\n").indent(indent)
  end

  def is_reverse_link_type?(link_path)
    # if "role_appointments" is at the root of the link_path, it's not the
    # reverse kind ':|
    return false if link_path == %i[role_appointments]

    link_type = link_path.last

    ExpansionRules.is_reverse_link_type?(link_type)
  end

  def is_a_top_level_link?(link_path)
    link_path.size == 1
  end

  def supported_top_level_reverse_link_type?(reverse_link_type)
    case reverse_link_type
    when :child_taxons
      @schema_name == "taxon"
    when :level_one_taxons
      @schema_name == "homepage"
    when :ministers, :policies
      false
    else
      true
    end
  end

  def build_links_query(link_path, links)
    link_type = link_path.last

    document_types = if is_reverse_link_type?(link_path)
                       # Content Schemas include a few irrelevant-looking
                       # top-level link types that all happen to be reverse
                       # link types
                       return if is_a_top_level_link?(link_path) &&
                         !supported_top_level_reverse_link_type?(link_type)

                       flip_reversed_link_types = ExpansionRules.reverse_to_direct_link_type(link_type)

                       flip_reversed_link_types
                         .flat_map {
                           link_types_source_document_types.fetch(_1, [])
                         }.uniq
                     else
                       link_types_target_document_types.fetch(link_type, [])
                     end

    link = links.first || {}

    return if document_types.empty? && link.empty?

    unless document_types.empty?
      link = document_types.map { |document_type|
               # ExpansionRules.expand_fields returns its fields in the form of
               # a hash that looks like a content item, but with null values,
               # e.g.
               #
               # { base_path: nil, content_id: nil }
               ExpansionRules.expand_fields({ document_type: }, link_type:, draft: false)
                 .deep_stringify_keys
             }
               .inject(link) do |link, expanded_fields_item|
                 expanded_fields_item.deep_merge(link)
               end
    end

    link.delete("details") if link["details"].blank?
    link.delete("links") if link["links"].blank?

    if link_path.size < MAX_LINK_DEPTH
      next_level_links = allowed_link_types(link_path)

      unless next_level_links.empty?
        link["links"] ||= {}

        next_level_links.each do |next_link_type|
          if link["links"][next_link_type.to_s].nil?
            link["links"][next_link_type.to_s] = []
          end
        end
      end
    end

    [
      "#{link_type} {",
      build_fields(link, link_path:),
      "}",
    ].join("\n").indent(2)
  end

  def allowed_link_types(link_path)
    ExpansionRules::MultiLevelLinks
      .new(ExpansionRules::MULTI_LEVEL_LINK_PATHS)
      .allowed_link_types(link_path)
  end

  def edition_type_or_subtype
    if @schema_name == "ministers_index"
      "MinistersIndex"
    else
      "Edition"
    end
  end

  def link_types_target_document_types
    @link_types_target_document_types ||= {
      active_top_level_browse_page: %w[mainstream_browse_page],
      associated_taxons: %w[taxon],
      children: %w[mainstream_browse_page redirect],
      contact: %w[contact],
      contacts: %w[contact],
      content_owners: %w[service_manual_guide],
      corporate_information_pages: %w[about about_our_services access_and_opening accessible_documents_policy complaints_procedure equality_and_diversity media_enquiries membership modern_slavery_statement our_energy_use our_governance personal_information_charter petitions_and_campaigns procurement publication_scheme recruitment redirect research social_media_use staff_update statistics terms_of_reference welsh_language_scheme],
      current_prime_minister: %w[person],
      documents: %w[about about_our_services access_and_opening accessible_documents_policy answer authored_article call_for_evidence_outcome case_study closed_call_for_evidence closed_consultation cma_case coming_soon complaints_procedure consultation_outcome contact coronavirus_landing_page corporate_report correspondence countryside_stewardship_grant decision detailed_guide document_collection drcf_digital_markets_research drug_safety_update equality_and_diversity export_health_certificate finder flood_and_coastal_erosion_risk_management_research_report foi_release form government_response guidance guide hmrc_manual hmrc_manual_section html_publication impact_assessment independent_report international_treaty local_transaction maib_report mainstream_browse_page manual manual_section map medical_safety_alert ministerial_role national_statistics national_statistics_announcement news_story notice official_statistics official_statistics_announcement open_call_for_evidence open_consultation oral_statement organisation our_governance personal_information_charter place placeholder policy_paper press_release procurement promotional recruitment redirect regulation research service_manual_guide service_manual_homepage simple_smart_answer smart_answer special_route speech staff_update standard statistical_data_set statistics statutory_guidance step_by_step_nav taxon terms_of_reference topical_event transaction transparency travel_advice travel_advice_index working_group world_news_story written_statement],
      email_alert_signup: %w[email_alert_signup finder_email_signup],
      embed: %w[content_block_pension],
      facet_group: %w[facet_group],
      facet_groups: %w[facet_group],
      facet_values: %w[facet_value],
      facets: %w[facet],
      fatality_notices: %w[fatality_notice],
      featured_policies: %w[policy],
      field_of_operation: %w[field_of_operation],
      fields_of_operation: %w[field_of_operation],
      finder: %w[finder],
      government: %w[government],
      historical_accounts: %w[historic_appointment],
      home_page_offices: %w[worldwide_office],
      lead_organisations: %w[organisation],
      linked_items: %w[service_manual_guide],
      main_office: %w[worldwide_office],
      mainstream_browse_pages: %w[mainstream_browse_page redirect],
      manual: %w[manual],
      ministerial: %w[ministers_index],
      office_staff: %w[person],
      ordered_also_attends_cabinet: %w[person],
      ordered_assistant_whips: %w[person],
      ordered_baronesses_and_lords_in_waiting_whips: %w[person],
      ordered_board_members: %w[person],
      ordered_cabinet_ministers: %w[person],
      ordered_chief_professional_officers: %w[person],
      ordered_child_organisations: %w[organisation],
      ordered_contacts: %w[contact],
      ordered_current_appointments: %w[role_appointment],
      ordered_featured_policies: %w[policy],
      ordered_foi_contacts: %w[contact],
      ordered_high_profile_groups: %w[organisation],
      ordered_house_lords_whips: %w[person],
      ordered_house_of_commons_whips: %w[person],
      ordered_junior_lords_of_the_treasury_whips: %w[person],
      ordered_military_personnel: %w[person],
      ordered_ministerial_departments: %w[organisation],
      ordered_ministers: %w[person],
      ordered_parent_organisations: %w[organisation],
      ordered_previous_appointments: %w[role_appointment],
      ordered_related_items: %w[about about_our_services answer business_support business_support_finder calendar call_for_evidence_outcome campaign case_study closed_call_for_evidence cma_case complaints_procedure consultation_outcome contact coronavirus_landing_page corporate_report correspondence decision detailed_guide document_collection finder flood_and_coastal_erosion_risk_management_research_report form government_response guidance guide help_page historic_appointment hmrc_manual hmrc_manual_section html_publication independent_report landing_page licence licence_transaction local_transaction mainstream_browse_page manual manual_section national_statistics news_story notice official_statistics our_governance person personal_information_charter place policy_paper press_release promotional redirect research simple_smart_answer smart_answer special_route speech standard statistical_data_set statistics statutory_guidance step_by_step_nav taxon topical_event transaction transparency travel_advice travel_advice_index video world_location_news written_statement],
      ordered_related_items_overrides: %w[answer call_for_evidence_outcome consultation_outcome correspondence detailed_guide document_collection finder guidance guide html_publication independent_report local_transaction manual national_statistics news_story place policy_paper press_release simple_smart_answer smart_answer statistical_data_set taxon transaction written_statement],
      ordered_roles: %w[ambassador_role board_member_role chief_professional_officer_role chief_scientific_advisor_role deputy_head_of_mission_role governor_role high_commissioner_role military_role ministerial_role special_representative_role traffic_commissioner_role worldwide_office_staff_role],
      ordered_special_representatives: %w[person],
      ordered_successor_organisations: %w[organisation],
      ordered_traffic_commissioners: %w[person],
      organisations: %w[contact organisation worldwide_office worldwide_organisation],
      original_primary_publishing_organisation: %w[organisation],
      pages_part_of_step_nav: %w[answer completed_transaction contact detailed_guide document_collection finder form guidance guide html_publication licence_transaction local_transaction manual notice place placeholder redirect simple_smart_answer smart_answer step_by_step_nav transaction travel_advice_index],
      pages_related_to_step_nav: %w[answer detailed_guide document_collection guidance guide html_publication local_transaction manual place simple_smart_answer smart_answer step_by_step_nav transaction travel_advice_index],
      pages_secondary_to_step_nav: %w[answer completed_transaction detailed_guide document_collection form guidance guide html_publication notice statutory_guidance transaction],
      parent: %w[answer call_for_evidence_outcome closed_call_for_evidence closed_consultation coming_soon consultation_outcome corporate_report correspondence decision facet facet_group finder foi_release form guidance guide history impact_assessment independent_report international_treaty mainstream_browse_page map national_statistics notice official_statistics open_call_for_evidence open_consultation organisation placeholder policy policy_paper promotional redirect regulation research service_manual_homepage service_manual_service_standard standard statutory_guidance topical_event transaction transparency travel_advice_index world_index worldwide_organisation],
      parent_taxons: %w[taxon],
      people: %w[person],
      person: %w[person placeholder_person],
      policies: %w[placeholder policy],
      policy_areas: %w[policy_area],
      popular_links: %w[link_collection],
      press_releases: %w[financial_release redirect],
      primary_publishing_organisation: %w[finder organisation],
      primary_role_person: %w[person],
      related: %w[contact detailed_guide document_collection finder guidance guide html_publication mainstream_browse_page smart_answer statutory_guidance transaction],
      related_guides: %w[detailed_guide],
      related_mainstream: %w[answer business_support_finder detailed_guide document_collection guidance guide local_transaction mainstream_browse_page placeholder simple_smart_answer smart_answer transaction travel_advice_index world_location],
      related_mainstream_content: %w[about accessible_documents_policy answer business_support_finder case_study contact coronavirus_landing_page corporate_report detailed_guide document_collection equality_and_diversity flood_and_coastal_erosion_risk_management_research_report form guidance guide html_publication licence local_transaction mainstream_browse_page manual manual_section news_story notice organisation personal_information_charter place placeholder policy_paper redirect research simple_smart_answer smart_answer statutory_guidance step_by_step_nav taxon topical_event transaction transparency travel_advice travel_advice_index working_group],
      related_policies: %w[placeholder policy redirect],
      related_statistical_data_sets: %w[statistical_data_set],
      related_topics: %w[redirect],
      role: %w[ambassador_role board_member_role chief_professional_officer_role chief_scientific_advisor_role deputy_head_of_mission_role governor_role high_commissioner_role military_role ministerial_role special_representative_role traffic_commissioner_role worldwide_office_staff_role],
      role_appointments: %w[role_appointment],
      roles: %w[ambassador_role board_member_role chief_scientific_advisor_role deputy_head_of_mission_role governor_role high_commissioner_role military_role ministerial_role special_representative_role worldwide_office_staff_role],
      root_taxon: %w[homepage],
      second_level_browse_pages: %w[mainstream_browse_page redirect],
      secondary_role_person: %w[person],
      sections: %w[manual_section],
      service_manual_topics: %w[service_manual_topic],
      speaker: %w[person],
      sponsoring_organisations: %w[organisation],
      suggested_ordered_related_items: %w[aaib_report about about_our_services access_and_opening accessible_documents_policy animal_disease_case answer asylum_support_decision authored_article business_finance_support_scheme calendar case_study cma_case complaints_procedure coronavirus_landing_page corporate_report correspondence countryside_stewardship_grant decision detailed_guide document_collection drcf_digital_markets_research drug_safety_update employment_appeal_tribunal_decision employment_tribunal_decision equality_and_diversity esi_fund export_health_certificate flood_and_coastal_erosion_risk_management_research_report foi_release form get_involved gone government_response guidance guide help_page history hmrc_manual impact_assessment independent_report international_development_fund international_treaty licence local_transaction maib_report manual map media_enquiries medical_safety_alert membership ministers_index modern_slavery_statement national_statistics national_statistics_announcement news_story notice official_statistics official_statistics_announcement oim_project oral_statement our_energy_use our_governance personal_information_charter petitions_and_campaigns place placeholder policy_paper press_release procurement product_safety_alert_report_recall promotional protected_food_drink_name publication_scheme raib_report recruitment redirect regulation research research_for_development_output residential_property_tribunal_decision service_manual_guide service_manual_service_standard service_manual_service_toolkit service_sign_in service_standard_report simple_smart_answer smart_answer social_media_use special_route speech staff_update standard statistical_data_set statistics statistics_announcement statutory_guidance statutory_instrument step_by_step_nav tax_tribunal_decision terms_of_reference topical_event_about_page transaction transparency travel_advice travel_advice_index uk_market_conformity_assessment_body utaac_decision welsh_language_scheme working_group world_news_story written_statement],
      supporting_organisations: %w[organisation],
      taxonomy_topic_email_override: %w[taxon],
      taxons: %w[taxon],
      top_level_browse_pages: %w[mainstream_browse_page],
      topical_events: %w[topical_event],
      topics: %w[redirect service_manual_topic],
      working_groups: %w[working_group],
      world_locations: %w[world_location world_location_news],
      worldwide_organisation: %w[worldwide_organisation],
      worldwide_organisations: %w[worldwide_organisation],
      worldwide_priorities: %w[placeholder],
    }
  end

  def link_types_source_document_types
    @link_types_source_document_types ||= {
      documents: %w[document_collection placeholder],
      ministerial: %w[ministerial_role],
      pages_part_of_step_nav: %w[step_by_step_nav],
      pages_related_to_step_nav: %w[step_by_step_nav],
      pages_secondary_to_step_nav: %w[step_by_step_nav],
      parent: %w[about about_our_services access_and_opening accessible_documents_policy answer authored_article business_support calendar call_for_evidence_outcome case_study closed_call_for_evidence closed_consultation coming_soon complaints_procedure consultation_outcome contact corporate_report correspondence decision detailed_guide document_collection email_alert_signup embassies_index equality_and_diversity facet facet_value finder foi_release form government_response guidance guide historic_appointment historic_appointments html_publication impact_assessment independent_report international_treaty licence local_transaction mainstream_browse_page manual map media_enquiries membership national_statistics news_story notice official_statistics oral_statement our_governance personal_information_charter place placeholder policy_paper press_release procurement programme promotional publication_scheme recruitment redirect regulation research service_manual_guide service_manual_topic service_sign_in services_and_information simple_smart_answer smart_answer social_media_use special_route speech staff_update standard statistical_data_set statistics statutory_guidance step_by_step_nav terms_of_reference topical_event_about_page transaction transparency travel_advice travel_advice_index video welsh_language_scheme world_news_story worldwide_office written_statement],
      parent_taxons: %w[taxon],
      person: %w[historic_appointment role_appointment],
      role: %w[role_appointment],
      root_taxon: %w[taxon],
      working_groups: %w[policy],
    }
  end
end
