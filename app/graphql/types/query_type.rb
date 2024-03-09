# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    field :node, Types::NodeType, null: true, description: "Fetches an object given its ID." do
      argument :id, ID, required: true, description: "ID of the object."
    end

    def node(id:)
      context.schema.object_from_id(id, context)
    end

    field :nodes, [Types::NodeType, null: true], null: true, description: "Fetches a list of objects given a list of IDs." do
      argument :ids, [ID], required: true, description: "IDs of the objects."
    end

    def nodes(ids:)
      ids.map { |id| context.schema.object_from_id(id, context) }
    end

    # Add root-level fields here.
    # They will be entry points for queries on your schema.

    field :person, Types::PersonType, extras: %i[lookahead], description: "Get a person" do
      argument :content_id, String
    end

    def person(content_id:, lookahead:)
      edition = Queries::GetEditionForContentStore.relation(content_id, "en")
      # TODO could do some plucking based on the lookahead here for efficiency
      edition.first
    end
  end
end
