# frozen_string_literal: true

module Types
  class PersonType < Types::EditionType
    description "A person"
    field :full_name, String
    field :roles, [RoleType]
    field :body, String
    field :image_url, String
    field :image_alt_text, String
    field :privy_counsellor, Boolean

    def full_name
      object.details[:full_name]
    end

    def body
      object.details.dig(:body, 0, :content)
    end

    def image_url
      object.details.dig(:image, :url)
    end

    def image_alt_text
      object.details.dig(:image, :alt_text)
    end

    def privy_counsellor
      object.details.fetch(:privy_counsellor, false)
    end

    def roles
      # Find the role appointments that link to this person
      role_appointment_content_ids = Queries::Links.to(
        object.content_id,
        allowed_link_types: %i[person],
      )[:person].map{ _1[:content_id] }

      # Select only the current role appointments
      role_appointment_content_ids = role_appointment_content_ids.filter do |content_id|
        edition = Queries::GetEditionForContentStore.relation(content_id, "en").where(state: "published").first
        edition.present? && edition.details.dig(:current)
      end

      # Find the roles that these role appointments link to
      role_content_ids = role_appointment_content_ids.flat_map do |content_id|
        Queries::Links.from(content_id, allowed_link_types: %i[role])[:role].map{ _1[:content_id] }
      end

      # Get the latest edition for each role
      dataloader.with(Sources::EditionSource).load_all(role_content_ids)
    end
  end
end
