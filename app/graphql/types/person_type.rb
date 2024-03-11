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
      role_appointment_content_ids = dataloader.with(Sources::LinkSetLinksToSource, %i[person])
                                               .load(object.content_id)
                                               .map do |link|
                                                  link.link_set.content_id
                                                end

      # Select only the current role appointments
      role_appointment_editions = dataloader.with(Sources::EditionSource).load_all(role_appointment_content_ids)
      role_appointment_content_ids = role_appointment_editions.filter do |edition|
        edition.present? && edition.details.dig(:current)
      end.map(&:content_id)

      # Find the roles that these role appointments link to
      role_content_ids = dataloader.with(Sources::LinkSetLinksFromSource, %i[role])
                                   .load_all(role_appointment_content_ids)
                                   .flat_map do |links|
                                     links.map do |link|
                                       link.target_content_id
                                     end
                                   end

      # Get the latest edition for each role
      dataloader.with(Sources::EditionSource).load_all(role_content_ids)
    end
  end
end
