# frozen_string_literal: true

module Types
  class WorldIndexType < Types::EditionType
    def self.document_types = %w[world_index]

    class WorldLocation < Types::BaseObject
      field :active, Boolean, null: false
      field :analytics_identifier, String
      field :content_id, ID, null: false
      field :iso2, String
      field :name, String, null: false
      field :slug, String, null: false
      field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    end

    class WorldIndexDetails < BaseObject
      field :body, String
      field :international_delegations, [WorldLocation], null: false
      field :world_locations, [WorldLocation], null: false
    end

    field :details, WorldIndexDetails
  end
end
