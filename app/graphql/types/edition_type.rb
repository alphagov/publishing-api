# frozen_string_literal: true

module Types
  class EditionType < Types::BaseObject
    class WithdrawnNotice < Types::BaseObject
      field :explanation, String
      field :withdrawn_at, Types::ContentApiDatetime
    end

    class EditionLinks < Types::BaseObject
      links_field :active_top_level_browse_page, [EditionType]
      links_field :associated_taxons, [EditionType]
      links_field :contact, [EditionType]
      links_field :contacts, [EditionType]
      links_field :content_owners, [EditionType]
      links_field :corporate_information_pages, [EditionType]
      links_field :current_prime_minister, [EditionType]
      links_field :documents, [EditionType]
      links_field :email_alert_signup, [EditionType]
      links_field :embed, [EditionType]
      links_field :fatality_notices, [EditionType]
      links_field :featured_policies, [EditionType]
      links_field :field_of_operation, [EditionType]
      links_field :fields_of_operation, [EditionType]
      links_field :finder, [EditionType]
      links_field :government, [EditionType]
      links_field :historical_accounts, [EditionType]
      links_field :home_page_offices, [EditionType]
      links_field :lead_organisations, [EditionType]
      links_field :linked_items, [EditionType]
      links_field :main_office, [EditionType]
      links_field :mainstream_browse_pages, [EditionType]
      links_field :manual, [EditionType]
      links_field :ministerial, [EditionType]
      links_field :office_staff, [EditionType]
      links_field :ordered_board_members, [EditionType]
      links_field :ordered_chief_professional_officers, [EditionType]
      links_field :ordered_child_organisations, [EditionType]
      links_field :ordered_contacts, [EditionType]
      links_field :ordered_featured_policies, [EditionType]
      links_field :ordered_foi_contacts, [EditionType]
      links_field :ordered_high_profile_groups, [EditionType]
      links_field :ordered_military_personnel, [EditionType]
      links_field :ordered_ministers, [EditionType]
      links_field :ordered_parent_organisations, [EditionType]
      links_field :ordered_related_items_overrides, [EditionType]
      links_field :ordered_related_items, [EditionType]
      links_field :ordered_roles, [EditionType]
      links_field :ordered_special_representatives, [EditionType]
      links_field :ordered_successor_organisations, [EditionType]
      links_field :ordered_traffic_commissioners, [EditionType]
      links_field :organisations, [EditionType]
      links_field :pages_part_of_step_nav, [EditionType]
      links_field :pages_related_to_step_nav, [EditionType]
      links_field :pages_secondary_to_step_nav, [EditionType]
      links_field :parent_taxons, [EditionType]
      links_field :parent, [EditionType]
      links_field :people, [EditionType]
      links_field :person, [EditionType]
      links_field :policy_areas, [EditionType]
      links_field :popular_links, [EditionType]
      links_field :primary_publishing_organisation, [EditionType]
      links_field :primary_role_person, [EditionType]
      links_field :related_guides, [EditionType]
      links_field :related_mainstream_content, [EditionType]
      links_field :related_policies, [EditionType]
      links_field :related_statistical_data_sets, [EditionType]
      links_field :related_topics, [EditionType]
      links_field :related, [EditionType]
      links_field :role, [EditionType]
      links_field :roles, [EditionType]
      links_field :root_taxon, [EditionType]
      links_field :second_level_browse_pages, [EditionType]
      links_field :secondary_role_person, [EditionType]
      links_field :sections, [EditionType]
      links_field :service_manual_topics, [EditionType]
      links_field :speaker, [EditionType]
      links_field :sponsoring_organisations, [EditionType]
      links_field :suggested_ordered_related_items, [EditionType]
      links_field :take_part_pages, [EditionType]
      links_field :taxonomy_topic_email_override, [EditionType]
      links_field :taxons, [EditionType]
      links_field :top_level_browse_pages, [EditionType]
      links_field :topical_events, [EditionType]
      links_field :world_location_news, [EditionType]
      links_field :world_locations, [EditionType]
      links_field :worldwide_organisation, [EditionType]
      links_field :worldwide_organisations, [EditionType]

      reverse_links_field :child_taxons, :parent_taxons, [EditionType]
      reverse_links_field :children, :parent, [EditionType]
      reverse_links_field :document_collections, :documents, [EditionType]
      reverse_links_field :level_one_taxons, :root_taxon, [EditionType]
      reverse_links_field :ministers, :ministerial, [EditionType]
      reverse_links_field :part_of_step_navs, :pages_part_of_step_nav, [EditionType]
      reverse_links_field :policies, :working_groups, [EditionType]
      reverse_links_field :related_to_step_navs, :pages_related_to_step_nav, [EditionType]
      reverse_links_field :secondary_to_step_navs, :pages_secondary_to_step_nav, [EditionType]

      field :available_translations, [EditionType]
      field :role_appointments, [EditionType]

      def role_appointments
        if %w[role ministerial_role].include?(object.document_type)
          dataloader.with(
            Sources::ReverseLinkedToEditionsSource,
            content_store: object.content_store,
            locale: context[:root_edition].locale,
          )
            .load([object, "role"])
        else
          dataloader.with(
            Sources::ReverseLinkedToEditionsSource,
            content_store: object.content_store,
            locale: context[:root_edition].locale,
          )
            .load([object, "person"])
        end
      end

      def available_translations
        Presenters::Queries::AvailableTranslations.by_edition(object)
          .translation_editions
      end
    end

    class Details < Types::BaseObject
      field :about_page_link_text, GraphQL::Types::JSON
      field :access_and_opening_times, GraphQL::Types::JSON
      field :acronym, String
      field :alert_status, GraphQL::Types::JSON
      field :alternative_format_contact_email, GraphQL::Types::JSON
      field :appointments_without_historical_accounts, GraphQL::Types::JSON
      field :archive_notice, GraphQL::Types::JSON
      field :attachments, [GraphQL::Types::JSON]
      field :attends_cabinet_type, GraphQL::Types::JSON
      field :beta_message, GraphQL::Types::JSON
      field :beta, GraphQL::Types::JSON
      field :blocks, GraphQL::Types::JSON
      field :body, String
      field :born, GraphQL::Types::JSON
      field :brand, String
      field :breadcrumbs, GraphQL::Types::JSON
      field :brexit_no_deal_notice, GraphQL::Types::JSON
      field :cancellation_reason, GraphQL::Types::JSON
      field :cancelled_at, GraphQL::Types::JSON
      field :casualties, GraphQL::Types::JSON
      field :change_description, GraphQL::Types::JSON
      field :change_history, GraphQL::Types::JSON
      field :change_note, GraphQL::Types::JSON
      field :change_notes, GraphQL::Types::JSON
      field :child_section_groups, GraphQL::Types::JSON
      field :choose_sign_in, GraphQL::Types::JSON
      field :closing_date, GraphQL::Types::JSON
      field :collection_groups, GraphQL::Types::JSON
      field :collections, GraphQL::Types::JSON
      field :combine_mode, GraphQL::Types::JSON
      field :contact_form_links, [GraphQL::Types::JSON]
      field :contact_groups, GraphQL::Types::JSON
      field :contact_type, GraphQL::Types::JSON
      field :corporate_information_groups, GraphQL::Types::JSON
      field :country, GraphQL::Types::JSON
      field :current, Boolean
      field :dates_in_office, GraphQL::Types::JSON
      field :default_documents_per_page, GraphQL::Types::JSON
      field :default_news_image, GraphQL::Types::JSON
      field :default_order, GraphQL::Types::JSON
      field :delivered_on, GraphQL::Types::JSON
      field :department_analytics_profile, GraphQL::Types::JSON
      field :department_counts, GraphQL::Types::JSON
      field :description, String
      field :died, GraphQL::Types::JSON
      field :display_as_result_metadata, GraphQL::Types::JSON
      field :display_date, Types::ContentApiDatetime
      field :document_noun, GraphQL::Types::JSON
      field :document, GraphQL::Types::JSON
      field :document_type_label, GraphQL::Types::JSON
      field :documents, GraphQL::Types::JSON
      field :downtime_message, String
      field :email_address, GraphQL::Types::JSON
      field :email_addresses, [GraphQL::Types::JSON]
      field :email_filter_by, GraphQL::Types::JSON
      field :email_filter_facets, GraphQL::Types::JSON
      field :email_signup_link, GraphQL::Types::JSON
      field :email, GraphQL::Types::JSON
      field :emphasised_organisations, GraphQL::Types::JSON
      field :end_date, GraphQL::Types::JSON
      field :ended_on, Types::ContentApiDatetime
      field :external_related_links, GraphQL::Types::JSON
      field :facets, GraphQL::Types::JSON
      field :featured_attachments, GraphQL::Types::JSON
      field :filter_key, GraphQL::Types::JSON
      field :filter, GraphQL::Types::JSON
      field :filterable, GraphQL::Types::JSON
      field :final_outcome_attachments, GraphQL::Types::JSON
      field :final_outcome_detail, GraphQL::Types::JSON
      field :final_outcome_documents, GraphQL::Types::JSON
      field :final_outcome_publication_date, GraphQL::Types::JSON
      field :first_public_at, Types::ContentApiDatetime
      field :first_published_version, GraphQL::Types::JSON
      field :foi_exempt, GraphQL::Types::JSON
      field :format_display_type, GraphQL::Types::JSON
      field :format_name, GraphQL::Types::JSON
      field :format_sub_type, GraphQL::Types::JSON
      field :full_name, GraphQL::Types::JSON
      field :govdelivery_title, GraphQL::Types::JSON
      field :government, GraphQL::Types::JSON
      field :groups, GraphQL::Types::JSON
      field :header_links, GraphQL::Types::JSON
      field :header_section, GraphQL::Types::JSON
      field :headers, GraphQL::Types::JSON
      field :headings, GraphQL::Types::JSON
      field :held_on_another_website_url, GraphQL::Types::JSON
      field :hidden_search_terms, GraphQL::Types::JSON
      field :hide_chapter_navigation, GraphQL::Types::JSON
      field :image, GraphQL::Types::JSON
      field :important_board_members, GraphQL::Types::JSON
      field :interesting_facts, GraphQL::Types::JSON
      field :internal_name, String
      field :international_delegations, [GraphQL::Types::JSON]
      field :introduction, GraphQL::Types::JSON
      field :introductory_paragraph, GraphQL::Types::JSON
      field :key, GraphQL::Types::JSON
      field :label_text, GraphQL::Types::JSON
      field :label, GraphQL::Types::JSON
      field :language, GraphQL::Types::JSON
      field :latest_change_note, GraphQL::Types::JSON
      field :lgil_code, GraphQL::Types::JSON
      field :lgsl_code, GraphQL::Types::JSON
      field :link_items, GraphQL::Types::JSON
      field :location, GraphQL::Types::JSON
      field :logo, GraphQL::Types::JSON
      field :major_acts, GraphQL::Types::JSON
      field :manual, GraphQL::Types::JSON
      field :mapped_specialist_topic_content_id, GraphQL::Types::JSON
      field :max_cache_time, GraphQL::Types::JSON
      field :metadata, GraphQL::Types::JSON
      field :ministerial_role_counts, GraphQL::Types::JSON
      field :mission_statement, GraphQL::Types::JSON
      field :more_info_contact_form, GraphQL::Types::JSON
      field :more_info_email_address, GraphQL::Types::JSON
      field :more_info_phone_number, GraphQL::Types::JSON
      field :more_info_post_address, GraphQL::Types::JSON
      field :more_info_webchat, GraphQL::Types::JSON
      field :more_information, GraphQL::Types::JSON
      field :name, GraphQL::Types::JSON
      field :national_applicability, GraphQL::Types::JSON
      field :navigation_groups, GraphQL::Types::JSON
      field :need_to_know, GraphQL::Types::JSON
      field :nodes, GraphQL::Types::JSON
      field :northern_ireland_availability, GraphQL::Types::JSON
      field :notes_for_editors, String
      field :office_contact_associations, GraphQL::Types::JSON
      field :open_filter_on_load, GraphQL::Types::JSON
      field :opening_date, GraphQL::Types::JSON
      field :ordered_agencies_and_other_public_bodies, GraphQL::Types::JSON
      field :ordered_corporate_information_pages, GraphQL::Types::JSON
      field :ordered_devolved_administrations, GraphQL::Types::JSON
      field :ordered_executive_offices, GraphQL::Types::JSON
      field :ordered_featured_documents, GraphQL::Types::JSON
      field :ordered_featured_links, GraphQL::Types::JSON
      field :ordered_high_profile_groups, GraphQL::Types::JSON
      field :ordered_ministerial_departments, GraphQL::Types::JSON
      field :ordered_non_ministerial_departments, GraphQL::Types::JSON
      field :ordered_promotional_features, GraphQL::Types::JSON
      field :ordered_public_corporations, GraphQL::Types::JSON
      field :ordered_second_level_browse_pages, GraphQL::Types::JSON
      field :ordering, GraphQL::Types::JSON
      field :organisation_featuring_priority, GraphQL::Types::JSON
      field :organisation_govuk_status, GraphQL::Types::JSON
      field :organisation_political, GraphQL::Types::JSON
      field :organisation_type, GraphQL::Types::JSON
      field :organisation, GraphQL::Types::JSON
      field :organisations, GraphQL::Types::JSON
      field :other_ways_to_apply, GraphQL::Types::JSON
      field :outcome_attachments, GraphQL::Types::JSON
      field :outcome_detail, GraphQL::Types::JSON
      field :outcome_documents, GraphQL::Types::JSON
      field :outcome_publication_date, GraphQL::Types::JSON
      field :parts, GraphQL::Types::JSON
      field :people_role_associations, GraphQL::Types::JSON
      field :person_appointment_order, GraphQL::Types::JSON
      field :phone_numbers, [GraphQL::Types::JSON]
      field :place_type, GraphQL::Types::JSON
      field :political_party, GraphQL::Types::JSON
      field :political, Boolean
      field :post_addresses, [GraphQL::Types::JSON]
      field :preposition, GraphQL::Types::JSON
      field :previous_display_date, GraphQL::Types::JSON
      field :privy_counsellor, Boolean
      field :promotion, GraphQL::Types::JSON
      field :public_feedback_attachments, GraphQL::Types::JSON
      field :public_feedback_detail, GraphQL::Types::JSON
      field :public_feedback_documents, GraphQL::Types::JSON
      field :public_feedback_publication_date, GraphQL::Types::JSON
      field :public_timestamp, GraphQL::Types::JSON
      field :query_response_time, GraphQL::Types::JSON
      field :quick_links, GraphQL::Types::JSON
      field :rates, GraphQL::Types::JSON
      field :read_more, GraphQL::Types::JSON
      field :reject, GraphQL::Types::JSON
      field :related_mainstream_content, GraphQL::Types::JSON
      field :reshuffle_in_progress, GraphQL::Types::JSON
      field :reshuffle, GraphQL::Types::JSON
      field :reviewed_at, GraphQL::Types::JSON
      field :role_payment_type, String
      field :roll_call_introduction, GraphQL::Types::JSON
      field :second_level_ordering, GraphQL::Types::JSON
      field :secondary_corporate_information_pages, GraphQL::Types::JSON
      field :section_id, GraphQL::Types::JSON
      field :sections, GraphQL::Types::JSON
      field :seniority, Integer
      field :service_tiers, GraphQL::Types::JSON
      field :services, GraphQL::Types::JSON
      field :short_name, GraphQL::Types::JSON
      field :show_description, GraphQL::Types::JSON
      field :show_metadata_block, GraphQL::Types::JSON
      field :show_summaries, GraphQL::Types::JSON
      field :show_table_of_contents, GraphQL::Types::JSON
      field :signup_link, GraphQL::Types::JSON
      field :slug, GraphQL::Types::JSON
      field :social_media_links, GraphQL::Types::JSON
      field :sort, GraphQL::Types::JSON
      field :speaker_without_profile, GraphQL::Types::JSON
      field :speech_type_explanation, GraphQL::Types::JSON
      field :start_button_text, GraphQL::Types::JSON
      field :start_date, GraphQL::Types::JSON
      field :started_on, Types::ContentApiDatetime
      field :state, GraphQL::Types::JSON
      field :step_by_step_nav, GraphQL::Types::JSON
      field :subscriber_list, GraphQL::Types::JSON
      field :subscription_list_title_prefix, GraphQL::Types::JSON
      field :summary, GraphQL::Types::JSON
      field :supports_historical_accounts, Boolean
      field :tags, GraphQL::Types::JSON
      field :temporary_update_type, GraphQL::Types::JSON
      field :theme, GraphQL::Types::JSON
      field :title, String
      field :transaction_start_link, GraphQL::Types::JSON
      field :type, GraphQL::Types::JSON
      field :updated_at, GraphQL::Types::JSON
      field :url_override, String
      field :url, GraphQL::Types::JSON
      field :value, GraphQL::Types::JSON
      field :variants, GraphQL::Types::JSON
      field :visible_to_departmental_editors, Boolean
      field :visually_collapsed, GraphQL::Types::JSON
      field :visually_expanded, GraphQL::Types::JSON
      field :ways_to_respond, GraphQL::Types::JSON
      field :what_you_need_to_know, GraphQL::Types::JSON
      field :whip_organisation, GraphQL::Types::JSON
      field :will_continue_on, GraphQL::Types::JSON
      field :world_location_names, [GraphQL::Types::JSON]
      field :world_location_news_type, GraphQL::Types::JSON
      field :world_locations, [GraphQL::Types::JSON]
    end

    field :active, Boolean, null: false
    field :analytics_identifier, String
    field :api_path, String
    field :api_url, String
    field :base_path, String
    field :change_history, GraphQL::Types::JSON
    field :content_id, ID
    field :current, Boolean
    field :description, String
    field :details, Details, extras: [:lookahead]
    field :details_json, GraphQL::Types::JSON
    field :document_type, String
    field :ended_on, Types::ContentApiDatetime
    field :first_published_at, Types::ContentApiDatetime, null: false
    field :iso2, String
    field :links, EditionLinks, method: :itself
    field :locale, String, null: false
    field :name, String, null: false
    field :phase, String, null: false
    field :public_updated_at, Types::ContentApiDatetime, null: false
    field :publishing_app, String
    field :publishing_request_id, String
    field :publishing_scheduled_at, Types::ContentApiDatetime
    field :rendering_app, String
    field :scheduled_publishing_delay_seconds, Int
    field :schema_name, String
    field :slug, String, null: false
    field :started_on, Types::ContentApiDatetime
    field :state, String
    field :supports_historical_accounts, Boolean
    field :title, String, null: false
    field :updated_at, Types::ContentApiDatetime
    field :web_url, String
    field :withdrawn_notice, WithdrawnNotice

    def details(lookahead:)
      requested_details_fields = lookahead.selections.map(&:name)
      object.details = object.details.slice(*requested_details_fields)

      change_history_presenter = Presenters::ChangeHistoryPresenter.new(object) if requested_details_fields.include?(:change_history)
      content_embed_presenter = Presenters::ContentEmbedPresenter.new(object)

      Presenters::ContentTypeResolver.new("text/html").resolve(
        Presenters::DetailsPresenter.new(
          object.details,
          change_history_presenter,
          content_embed_presenter,
          locale: object.locale,
        ).details,
      )
    end

    def details_json
      object.details
    end

    def withdrawn_notice
      return nil unless object.unpublishing&.withdrawal?

      presented_edition.fetch(:withdrawn_notice)
    end

    # Aliased by field methods for fields that are currently presented in the
    # content item, but come from Content Store, so we can't provide them here
    def not_stored_in_publishing_api
      nil
    end

    alias_method :publishing_scheduled_at, :not_stored_in_publishing_api
    alias_method :scheduled_publishing_delay_seconds, :not_stored_in_publishing_api

  private

    def presented_edition
      @presented_edition ||= Presenters::EditionPresenter
        .new(object)
        .present
    end
  end
end
