# frozen_string_literal: true

module Types
  class WorldIndexType < Types::EditionType
    class WorldLocation < Types::BaseObject
      field :active, Boolean, null: false
      field :analytics_identifier, String
      field :content_id, ID, null: false
      field :iso2, String
      field :name, String, null: false
      field :slug, String, null: false
      field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    end

    field :body, String
    field :international_delegations, [WorldLocation], null: false
    field :world_locations, [WorldLocation], null: false

    def self.base_path = "/world"

    def international_delegations
      object.details[:international_delegations]
    end

    def world_locations
      object.details[:world_locations]
    end
  end
end
