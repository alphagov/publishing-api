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
        class PersonDetails < Types::BaseObject
          field :body, String

          def body
            govspeak = object.fetch(:body, [])
              .filter { _1[:content_type] == "text/govspeak" }
              .map { _1[:content] }
              .first

            Govspeak::Document.new(govspeak).to_html if govspeak.present?
          end
        end

        field :base_path, String
        field :details, PersonDetails
        field :title, String, null: false
      end

      class RoleAppointmentDetails < Types::BaseObject
        field :current, Boolean
        field :ended_on, GraphQL::Types::ISO8601DateTime
        field :started_on, GraphQL::Types::ISO8601DateTime
      end

      field :details, RoleAppointmentDetails

      class RoleAppointmentLinks < Types::BaseObject
        field :person, [Person]

        def person
          Edition
            .live
            .joins(document: { reverse_links: :link_set })
            .where(
              document: { locale: "en" },
              link_set: { content_id: object.content_id },
              reverse_links: { link_type: "person" },
            )
            .limit(1)
        end
      end

      field :links, RoleAppointmentLinks, method: :itself
    end

    class Translation < Types::BaseObject
      field :locale, String
      field :base_path, String
    end

    class RoleDetails < Types::BaseObject
      field :body, String
      field :supports_historical_accounts, Boolean

      def body
        govspeak = object.fetch(:body, [])
          .filter { _1[:content_type] == "text/govspeak" }
          .map { _1[:content] }
          .first

        Govspeak::Document.new(govspeak).to_html if govspeak.present?
      end
    end

    class RoleLinks < Types::BaseObject
      field :available_translations, [Translation]
      field :ordered_parent_organisations, [Organisation]
      field :role_appointments, [RoleAppointment]

      def available_translations
        Presenters::Queries::AvailableTranslations.by_edition(object)
          .translations.fetch(:available_translations, [])
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

      def role_appointments
        Edition
          .live
          .joins(document: :link_set_links)
          .where(
            document: { locale: "en" },
            link_set_links: { target_content_id: object.content_id, link_type: "role" },
          )
      end
    end

    field :details, RoleDetails
    field :links, RoleLinks, method: :itself
  end
end
