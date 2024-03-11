# frozen_string_literal: true

module Types
  class OrganisationType < Types::EditionType
    description "An organisation"
    field :ministers, [PersonType]

    def ministers
      link_set_links_from(link_types: %w[ordered_ministers]).map do |link|
        Queries::GetEditionForContentStore.call(link[:target_content_id], "en")
      end
    end
  end
end
