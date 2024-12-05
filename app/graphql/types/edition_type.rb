# frozen_string_literal: true

module Types
  class EditionType < Types::BaseObject
    class WithdrawnNotice < Types::BaseObject
      field :explanation, String
      field :withdrawn_at, GraphQL::Types::ISO8601DateTime
    end

    class EditionLinks < Types::BaseObject
      links_field :active_top_level_browse_page, [EditionType]
      links_field :associated_taxons, [EditionType]
      links_field :available_translations, [EditionType]
      links_field :child_taxons, [EditionType]
      links_field :children, [EditionType]
      links_field :contact, [EditionType]
      links_field :contacts, [EditionType]
      links_field :content_owners, [EditionType]
      links_field :corporate_information_pages, [EditionType]
      links_field :current_prime_minister, [EditionType]
      links_field :document_collections, [EditionType]
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
      links_field :level_one_taxons, [EditionType]
      links_field :linked_items, [EditionType]
      links_field :main_office, [EditionType]
      links_field :mainstream_browse_pages, [EditionType]
      links_field :manual, [EditionType]
      links_field :meets_user_needs, [EditionType]
      links_field :ministerial, [EditionType]
      links_field :ministers, [EditionType]
      links_field :office_staff, [EditionType]
      links_field :ordered_also_attends_cabinet, [EditionType]
      links_field :ordered_assistant_whips, [EditionType]
      links_field :ordered_baronesses_and_lords_in_waiting_whips, [EditionType]
      links_field :ordered_board_members, [EditionType]
      links_field :ordered_cabinet_ministers, [EditionType]
      links_field :ordered_chief_professional_officers, [EditionType]
      links_field :ordered_child_organisations, [EditionType]
      links_field :ordered_contacts, [EditionType]
      links_field :ordered_featured_policies, [EditionType]
      links_field :ordered_foi_contacts, [EditionType]
      links_field :ordered_high_profile_groups, [EditionType]
      links_field :ordered_house_lords_whips, [EditionType]
      links_field :ordered_house_of_commons_whips, [EditionType]
      links_field :ordered_junior_lords_of_the_treasury_whips, [EditionType]
      links_field :ordered_military_personnel, [EditionType]
      links_field :ordered_ministerial_departments, [EditionType]
      links_field :ordered_ministers, [EditionType]
      links_field :ordered_parent_organisations, [EditionType]
      links_field :ordered_related_items, [EditionType]
      links_field :ordered_related_items_overrides, [EditionType]
      links_field :ordered_roles, [EditionType]
      links_field :ordered_special_representatives, [EditionType]
      links_field :ordered_successor_organisations, [EditionType]
      links_field :ordered_traffic_commissioners, [EditionType]
      links_field :organisations, [EditionType]
      links_field :original_primary_publishing_organisation, [EditionType]
      links_field :pages_part_of_step_nav, [EditionType]
      links_field :pages_related_to_step_nav, [EditionType]
      links_field :pages_secondary_to_step_nav, [EditionType]
      links_field :parent, [EditionType]
      links_field :parent_taxons, [EditionType]
      links_field :part_of_step_navs, [EditionType]
      links_field :people, [EditionType]
      links_field :person, [EditionType]
      links_field :policies, [EditionType]
      links_field :policy_areas, [EditionType]
      links_field :popular_links, [EditionType]
      links_field :primary_publishing_organisation, [EditionType]
      links_field :primary_role_person, [EditionType]
      links_field :related, [EditionType]
      links_field :related_guides, [EditionType]
      links_field :related_mainstream_content, [EditionType]
      links_field :related_policies, [EditionType]
      links_field :related_statistical_data_sets, [EditionType]
      links_field :related_to_step_navs, [EditionType]
      links_field :related_topics, [EditionType]
      links_field :role, [EditionType]
      links_field :role_appointments, [EditionType]
      links_field :roles, [EditionType]
      links_field :root_taxon, [EditionType]
      links_field :second_level_browse_pages, [EditionType]
      links_field :secondary_role_person, [EditionType]
      links_field :secondary_to_step_navs, [EditionType]
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
      links_field :world_locations, [EditionType]
      links_field :worldwide_organisation, [EditionType]
      links_field :worldwide_organisations, [EditionType]
    end

    field :active, Boolean, null: false
    field :analytics_identifier, String
    field :base_path, String
    field :content_id, ID
    field :current, Boolean
    field :description, String
    field :details, GraphQL::Types::JSON, null: false
    field :document_type, String
    field :ended_on, GraphQL::Types::ISO8601DateTime
    field :first_published_at, GraphQL::Types::ISO8601DateTime, null: false
    field :iso2, String
    field :links, EditionLinks, method: :itself
    field :locale, String, null: false
    field :name, String, null: false
    field :phase, String, null: false
    field :public_updated_at, GraphQL::Types::ISO8601DateTime, null: false
    field :publishing_app, String
    field :publishing_request_id, String
    field :publishing_scheduled_at, GraphQL::Types::ISO8601DateTime
    field :rendering_app, String
    field :scheduled_publishing_delay_seconds, Int
    field :schema_name, String
    field :slug, String, null: false
    field :started_on, GraphQL::Types::ISO8601DateTime
    field :state, String
    field :supports_historical_accounts, Boolean
    field :title, String, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime
    field :web_url, String
    field :withdrawn_notice, WithdrawnNotice

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
