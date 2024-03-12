# frozen_string_literal: true

module Types
  class EditionType < Types::BaseObject
    description "An edition"
    field :content_id, String
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
    field :details, GenericDetailsType
    field :link_set_links_from, [LinkType] do
      argument :link_types, [String], required: false
      argument :first, Integer, required: false
    end
    field :link_set_links_to, [LinkType] do
      argument :link_types, [String], required: false
      argument :first, Integer, required: false
    end

    def details
      object.details.deep_stringify_keys
    end

    def link_set_links_from(link_types: nil, first: nil)
      result = dataloader.with(Sources::LinkSetLinksFromSource, link_types).load(object.content_id)
      first.present? ? result.take(first) : result
    end

    def link_set_links_to(link_types: nil, first: nil)
      result = dataloader.with(Sources::LinkSetLinksToSource, link_types).load(object.content_id)
      first.present? ? result.take(first) : result
    end
  end
end
