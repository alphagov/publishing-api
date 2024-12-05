# frozen_string_literal: true

module Types
  class EditionType < Types::BaseObject
    class WithdrawnNotice < Types::BaseObject
      field :explanation, String
      field :withdrawn_at, GraphQL::Types::ISO8601DateTime
    end

    class EditionLinks < Types::BaseObject
      links_field :available_translations, [EditionType]
      links_field :ordered_also_attends_cabinet, [EditionType]
      links_field :ordered_assistant_whips, [EditionType]
      links_field :ordered_baronesses_and_lords_in_waiting_whips, [EditionType]
      links_field :ordered_cabinet_ministers, [EditionType]
      links_field :ordered_house_lords_whips, [EditionType]
      links_field :ordered_house_of_commons_whips, [EditionType]
      links_field :ordered_junior_lords_of_the_treasury_whips, [EditionType]
      links_field :ordered_ministerial_departments, [EditionType]
      links_field :ordered_ministers, [EditionType]
      links_field :ordered_parent_organisations, [EditionType]
      links_field :ordered_roles, [EditionType]
      links_field :person, [EditionType]
      links_field :role_appointments, [EditionType]
      links_field :role, [EditionType]
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
