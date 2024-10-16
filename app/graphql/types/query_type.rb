# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    field :node, Types::NodeType, null: true, description: "Fetches an object given its ID." do
      argument :id, ID, required: true, description: "ID of the object."
    end

    def node(id:)
      context.schema.object_from_id(id, context)
    end

    field :nodes, [Types::NodeType, { null: true }], null: true, description: "Fetches a list of objects given a list of IDs." do
      argument :ids, [ID], required: true, description: "IDs of the objects."
    end

    def nodes(ids:)
      ids.map { |id| context.schema.object_from_id(id, context) }
    end

    # Add root-level fields here.
    # They will be entry points for queries on your schema.

    field :edition, Types::EditionType, null: false, description: "An edition" do
      argument :content_id, String
    end

    def edition(content_id:)
      Document.find_by(content_id:).live
    end

    field :world_index, Types::WorldIndexType, null: false, description: "World index"

    def world_index
      edition(content_id: "369729ba-7776-4123-96be-2e3e98e153e1")
    end
  end
end
