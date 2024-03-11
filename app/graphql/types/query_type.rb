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

    field :edition, Types::EditionType, description: "Get an edition" do
      argument :content_id, String, required: false
      argument :base_path, String, required: false
      validates required: { one_of: [:content_id, :base_path] }
    end

    def edition(content_id: nil, base_path: nil)
      if content_id.present?
        Queries::GetEditionForContentStore.call(content_id, "en")
      elsif base_path.present?
        Queries::GetEditionForBasePath.call(base_path, "en")
      else
        raise "Must have either content ID or base path"
      end
    end

    field :person, Types::PersonType, description: "Get a person" do
      argument :content_id, String, required: false
      argument :base_path, String, required: false
      validates required: { one_of: [:content_id, :base_path] }
    end
    alias_method :person, :edition

    field :ministers_index, Types::MinistersIndexType do
      argument :content_id, String, required: false
      argument :base_path, String, required: false
      validates required: { one_of: [:content_id, :base_path] }
    end
    alias_method :ministers_index, :edition
  end
end
