# frozen_string_literal: true

module Types
  class EditionType < Types::BaseObject
    description "An edition"
    field :full_name, String
    field :title, String
    field :public_updated_at, String
    field :publishing_app, String
    field :rendering_app, String
    field :update_type, String
    field :phase, String
    field :analytics_identifier, String
    field :created_at, String
    field :updated_at, String
    field :document_type, String
    field :schema_name, String
    field :first_published_at, String
    field :last_edited_at, String
    field :state, String
    field :user_facing_version, Integer
    field :base_path, String
    field :content_store, String
    field :document_id, Integer # TODO - probably a good idea to join document by default
    field :description, String
    field :publishing_request_id, String
    field :major_published_at, String
    field :published_at, String
    field :publishing_api_first_published_at, String
    field :publishing_api_last_edited_at, String
    field :details, String
    field :link_set_links_from, [LinkType] do
      argument :link_types, [String], required: false
    end

    def details
      object.details.deep_stringify_keys
    end

    def link_set_links_from(link_types: nil)
      query = Link
        .joins(:link_set)
        .where(link_sets: {content_id: object.content_id})

      if link_types.present?
        query = query.where(link_type: link_types)
      end

      query
        .order(link_type: :asc, position: :asc)
    end
  end
end
