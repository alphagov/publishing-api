# frozen_string_literal: true

module Types
  class OrganisationType < Types::EditionType
    description "An organisation"
    field :ministers, [PersonType]

    def ministers
      content_ids = link_set_links_from(link_types: %w[ordered_ministers]).map do |link|
        link[:target_content_id]
      end
      dataloader.with(Sources::EditionSource).load_all(content_ids)
    end
  end
end
