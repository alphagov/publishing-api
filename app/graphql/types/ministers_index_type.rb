module Types
  class MinistersIndexType < Types::EditionType
    def self.document_types = %w[ministers_index]

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
              field :role_payment_type, String
              field :seniority, Integer
              field :whip_organisation, GraphQL::Types::JSON
            end

            class MinistersIndexRoleLinks < Types::BaseObject
              class Organisation < Types::BaseObject
                field :content_id, String
              end

              # We can work backwards from the `ordered_roles` link_type which goes:
              #     Organisation --ordered_roles--> [Role]
              # To work out which organisations this role belongs to:
              reverse_links_field :organisations, :ordered_roles, [Organisation]
            end

            field :content_id, String
            field :details, MinistersIndexRoleDetails
            field :title, String
            field :web_url, String
            field :links, MinistersIndexRoleLinks, method: :itself
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
        field :image, GraphQL::Types::JSON
        field :privy_counsellor, Boolean
      end

      class MinistersIndexPersonLinks < Types::BaseObject
        field :role_appointments, [MinistersIndexRoleAppointment]

        def role_appointments
          dataloader.with(Sources::PersonCurrentRolesSource)
            .load(object.content_id)
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
        field :brand, String
        field :logo, GraphQL::Types::JSON
      end

      class DepartmentLinks < Types::BaseObject
        links_field :ordered_ministers, [MinistersIndexPerson]
        links_field :ordered_roles, [DepartmentRole]
      end

      field :details, DepartmentDetails
      field :links, DepartmentLinks, method: :itself
      field :title, String
      field :web_url, String
      field :content_id, String
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
