# frozen_string_literal: true

module Types
  class LinkType < Types::BaseObject
    description "A link"
    field :target_content_id, String
    field :link_type, String
    field :target_edition, EditionType

    def target_edition
      dataloader.with(Sources::EditionSource).load(object.target_content_id)
    end
  end
end
