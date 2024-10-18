# frozen_string_literal: true

module Types
  class WorldIndexType < Types::EditionType
    field :international_delegations, [WorldLocationType]
    field :world_locations, [WorldLocationType]

    def international_delegations
      simplify_world_locations(object.details[:international_delegations])
    end

    def world_locations
      simplify_world_locations(object.details[:world_locations])
    end

  private

    def simplify_world_locations(world_locations)
      world_locations.map { |world_location| world_location.slice(:active, :name, :slug) }
    end
  end
end
