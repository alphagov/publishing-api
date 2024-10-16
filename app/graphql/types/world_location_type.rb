# frozen_string_literal: true

module Types
  class WorldLocationType < Types::EditionType
    field :active, Boolean
    field :name, String
    field :slug, String
  end
end
