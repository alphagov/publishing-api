# frozen_string_literal: true

module Types
  class RoleType < Types::EditionType
    def self.document_type = "ministerial_role"

    class Organisation < Types::BaseObject
      field :base_path, String
      field :title, String, null: false
    end

    class RoleAppointment < Types::BaseObject
      class Person < Types::BaseObject
        field :base_path, String
        field :biography, String
        field :title, String, null: false

        def biography
          Presenters::EditionPresenter
            .new(object)
            .present
            .dig(:details, :body)
            .find { |body| body[:content_type] == "text/html" }[:content]
        end
      end

      field :ended_on, GraphQL::Types::ISO8601DateTime
      field :person, Person
      field :started_on, GraphQL::Types::ISO8601DateTime

      def ended_on
        object.details[:ended_on]
      end

      def person
        Edition
          .live
          .joins(document: { reverse_links: :link_set })
          .where(
            document: { locale: "en" },
            link_set: { content_id: object.content_id },
            reverse_links: { link_type: "person" },
          )
          .first
      end

      def started_on
        object.details[:started_on]
      end
    end

    class Translation < Types::BaseObject
      field :locale, String
      field :base_path, String
    end

    field :available_translations, [Translation]
    field :current_role_appointment, RoleAppointment
    field :ordered_parent_organisations, [Organisation]
    field :past_role_appointments, [RoleAppointment]
    field :responsibilities, String
    field :supports_historical_accounts, Boolean

    def available_translations
      Presenters::Queries::AvailableTranslations.by_edition(object)
        .translations.fetch(:available_translations, [])
    end

    def current_role_appointment
      Edition
        .live
        .joins(document: :link_set_links)
        .where(
          document: { locale: "en" },
          link_set_links: { target_content_id: object.content_id, link_type: "role" },
        )
        .where("details ->> 'current' = 'true'")
        .first
    end

    def ordered_parent_organisations
      Edition
        .live
        .joins(document: { reverse_links: :link_set })
        .where(
          document: { locale: "en" },
          link_set: { content_id: object.content_id },
          reverse_links: { link_type: "ordered_parent_organisations" },
        )
    end

    def past_role_appointments
      Edition
        .live
        .joins(document: :link_set_links)
        .where(
          document: { locale: "en" },
          link_set_links: { target_content_id: object.content_id, link_type: "role" },
        )
        .where("details ->> 'current' = 'false'")
    end

    def responsibilities
      presented_edition
        .dig(:details, :body)
        .find { |body| body[:content_type] == "text/html" }[:content]
    end

    def supports_historical_accounts
      object.details[:supports_historical_accounts]
    end
  end
end
