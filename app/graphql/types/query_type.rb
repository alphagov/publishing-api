# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    # Collections of editions

    field :editions, Types::EditionType.connection_type, description: "Collection of editions" do
      argument :content_purpose_supergroup, String, required: false
      argument :document_types, [String], required: false
      argument :order_by, String, required: false
    end

    field :governments, Types::GovernmentType.connection_type, description: "Collection of governments"

    def governments
      editions(document_types: %w[government], order_by: Arel.sql("details->>'started_on' desc"))
    end

    def editions(content_purpose_supergroup: nil, document_types: nil, order_by: nil)
      if content_purpose_supergroup.present?
        supergroup_document_types = GovukDocumentTypes.supergroup_document_types(content_purpose_supergroup)
        document_types = supergroup_document_types if supergroup_document_types.present?
      end

      query = Edition.joins(:document)
                     .where(state: 'published', document: { locale: 'en' })

      query = query.where(document_type: document_types) if document_types.present?

      query = if order_by == "popularity"
                query.order("random()") # TODO
              elsif order_by.present?
                query.order(order_by)
              else
                query.order(id: :desc)
              end

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
