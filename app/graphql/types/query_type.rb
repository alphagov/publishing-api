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

    # Collections of editions
    field :editions, Types::EditionType.connection_type, description: "Collection of editions" do
      argument :document_type, String, required: false
    end

    field :governments, Types::GovernmentType.connection_type, description: "Collection of governments"

    def governments
      # TODO - might be nice to put a custom ordering in here - with governments we probably don't want the most
      #     recently updated, we probably want them by start date / end date
      editions(document_type: "government")
    end

    def editions(document_type: nil)
      query = Edition.joins(:document)
                     .where(state: 'published', document: { locale: 'en' })

      query = query.where(document_type:) if document_type.present?

      Connections::EditionsConnection.new(
        query
      )
    end

    # Individual editions

    field :edition, Types::EditionType, description: "Get an edition" do
      argument :content_id, String, required: false
      argument :base_path, String, required: false
      validates required: { one_of: [:content_id, :base_path] }
    end

    def edition(content_id: nil, base_path: nil)
      if content_id.present?
        dataloader.with(Sources::EditionSource).load(content_id)
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

    alias_method :organisation, :edition
    field :organisation, Types::OrganisationType, description: "Get a organisation" do
      argument :content_id, String, required: false
      argument :base_path, String, required: false
      validates required: { one_of: [:content_id, :base_path] }
    end
    alias_method :organisation, :edition

    field :guide, Types::GuideType, description: "Get a guide" do
      argument :content_id, String, required: false
      argument :base_path, String, required: false
      validates required: { one_of: [:content_id, :base_path] }
    end
    alias_method :guide, :edition

    field :ministers_index, Types::MinistersIndexType do
      argument :content_id, String, required: false
      argument :base_path, String, required: false
      validates required: { one_of: [:content_id, :base_path] }
    end
    alias_method :ministers_index, :edition

    field :topical_event, Types::TopicalEventType do
      argument :content_id, String, required: false
      argument :base_path, String, required: false
      validates required: { one_of: [:content_id, :base_path] }
    end
    alias_method :topical_event, :edition
  end
end
