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
      field :available_translations, [EditionType]
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
      links_field :meets_user_needs, [EditionType]
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
      links_field :original_primary_publishing_organisation, [EditionType]
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
      reverse_links_field :secondary_to_step_navs, :secondary_to_step_navs, [EditionType]

      field :role_appointments, [EditionType], extras: [:lookahead]

      def role_appointments(lookahead:)
        selections = convert_edition_selections(lookahead:)

        if %w[role ministerial_role].include?(object.document_type)
          dataloader.with(Sources::ReverseLinkedToEditionsSource, content_store: object.content_store)
            .load([object, "role", selections])
        else
          dataloader.with(Sources::ReverseLinkedToEditionsSource, content_store: object.content_store)
            .load([object, "person", selections])
        end
      end

      def available_translations
        Presenters::Queries::AvailableTranslations.by_edition(object)
          .translations.fetch(:available_translations, [])
      end
    end

    class Details < Types::BaseObject
      class Image < Types::BaseObject
        field :url, String
        field :alt_text, String
      end

      class Logo < Types::BaseObject
        field :crest, String
        field :formatted_title, String
      end

      class WhipOrganisation < Types::BaseObject
        field :label, String
        field :sort_order, Integer
      end

      field :body, String
      field :brand, String
      field :change_history, GraphQL::Types::JSON
      field :current, Boolean
      field :default_news_image, Image
      field :display_date, GraphQL::Types::ISO8601DateTime
      field :emphasised_organisations, GraphQL::Types::JSON
      field :ended_on, GraphQL::Types::ISO8601DateTime
      field :first_public_at, GraphQL::Types::ISO8601DateTime
      field :image, Image
      field :international_delegations, [EditionType], null: false
      field :logo, Logo
      field :political, Boolean
      field :privy_counsellor, Boolean
      field :role_payment_type, String
      field :seniority, Integer
      field :started_on, GraphQL::Types::ISO8601DateTime
      field :supports_historical_accounts, Boolean
      field :whip_organisation, WhipOrganisation
      field :world_locations, [EditionType], null: false
    end

    field :active, Boolean, null: false
    field :analytics_identifier, String
    field :base_path, String
    field :change_history, GraphQL::Types::JSON
    field :content_id, ID
    field :current, Boolean
    field :description, String
    field :details, Details, extras: [:lookahead]
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
        ).details,
      )
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
