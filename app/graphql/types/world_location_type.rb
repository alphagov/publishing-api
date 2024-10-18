# frozen_string_literal: true

module Types
  class WorldLocationType < GraphQL::Schema::Object
    field :active, Boolean
    field :name, String
    field :slug, String
  end
end
