# frozen_string_literal: true

module Types
  class LinkType < Types::BaseObject
    description "A link"
    field :source_content_id, String
    field :target_content_id, String
    field :link_type, String
    field :target_edition, EditionType
    field :source_edition, EditionType

    def source_content_id
      object.link_set.content_id
    end

    def target_edition
      dataloader.with(Sources::EditionSource).load(object.target_content_id)
    end

    def source_edition
      dataloader.with(Sources::EditionSource).load(source_content_id)
    end
  end
end
