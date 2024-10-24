# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    field :world_index, Types::WorldIndexType, null: false, description: "World index"

    def world_index
      live_edition(content_id: "369729ba-7776-4123-96be-2e3e98e153e1")
    end

  private

    def live_edition(content_id:)
      Document.find_by(content_id:)&.live
    end
  end
end
