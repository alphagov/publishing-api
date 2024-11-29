# frozen_string_literal: true

module Types
  class MinistersIndexType < Types::EditionType
    def self.document_type = "ministers_index"

    class MinistersIndexPerson < Types::BaseObject
      class MinistersIndexRoleAppointment < Types::BaseObject
        class MinistersIndexRoleAppointmentDetails < Types::BaseObject
          field :current, Boolean

          def current
            true
          end
        end

        class MinistersIndexRoleAppointmentLinks < Types::BaseObject
          class MinistersIndexRole < Types::BaseObject
            class MinistersIndexRoleDetails < Types::BaseObject
              class MinistersIndexRoleDetailsWhipOrganisation < Types::BaseObject
                field :label, String
                field :sort_order, Integer
              end

              field :role_payment_type, String
              field :seniority, Integer
              field :whip_organisation, MinistersIndexRoleDetailsWhipOrganisation
            end

            field :content_id, String
            field :details, MinistersIndexRoleDetails
            field :title, String
            field :web_url, String
          end

          field :role, [MinistersIndexRole]

          def role
            [object]
          end
        end

        field :details, MinistersIndexRoleAppointmentDetails, method: :itself

        field :links, MinistersIndexRoleAppointmentLinks, method: :itself
      end

      class MinistersIndexPersonDetails < Types::BaseObject
        class Image < Types::BaseObject
          field :url, String
          field :alt_text, String
        end

        field :image, Image
        field :privy_counsellor, Boolean
      end

      class MinistersIndexPersonLinks < Types::BaseObject
        field :role_appointments, [MinistersIndexRoleAppointment]

        def role_appointments
          Edition
            .live
            .joins(
              document: {
                reverse_links: { # role -> role_appointment
                  link_set: {
                    documents: [
                      :editions, # role_appointment
                      :link_set_links, # role_appointment -> person
                    ],
                  },
                },
              },
            )
            .where(
              document_type: "ministerial_role",
              document: { locale: "en" },
              reverse_links: { link_type: "role" },
              editions_documents: { document_type: "role_appointment" },
              link_set_links: { target_content_id: object.content_id, link_type: "person" },
            )
            .where("editions_documents.details ->> 'current' = 'true'") # editions_documents is the alias that Active Record gives to the role_appointment Editions in the SQL query
            .order(reverse_links: { position: :asc })
        end
      end

      field :base_path, String
      field :details, MinistersIndexPersonDetails
      field :links, MinistersIndexPersonLinks, method: :itself
      field :title, String
      field :web_url, String
    end

    class Department < Types::BaseObject
      class DepartmentRole < Types::BaseObject
        field :content_id, String
      end

      class DepartmentDetails < Types::BaseObject
        class Logo < Types::BaseObject
          field :crest, String
          field :formatted_title, String
        end

        field :brand, String
        field :logo, Logo
      end

      class DepartmentLinks < Types::BaseObject
        links_field :ordered_ministers, [MinistersIndexPerson]
        links_field :ordered_roles, [DepartmentRole]
      end

      field :details, DepartmentDetails
      field :links, DepartmentLinks, method: :itself
      field :title, String
      field :web_url, String
    end

    class MinistersIndexLinks < Types::BaseObject
      links_field :ordered_also_attends_cabinet, [MinistersIndexPerson]
      links_field :ordered_assistant_whips, [MinistersIndexPerson]
      links_field :ordered_baronesses_and_lords_in_waiting_whips, [MinistersIndexPerson]
      links_field :ordered_cabinet_ministers, [MinistersIndexPerson]
      links_field :ordered_house_lords_whips, [MinistersIndexPerson]
      links_field :ordered_house_of_commons_whips, [MinistersIndexPerson]
      links_field :ordered_junior_lords_of_the_treasury_whips, [MinistersIndexPerson]

      links_field :ordered_ministerial_departments, [Department]
    end

    field :links, MinistersIndexLinks, method: :itself
  end
end
