# frozen_string_literal: true

module Types
  class EditionType < Types::BaseObject
    class WithdrawnNotice < Types::BaseObject
      field :explanation, String
      field :withdrawn_at, GraphQL::Types::ISO8601DateTime
    end

    field :analytics_identifier, String
    field :base_path, String
    field :content_id, ID
    field :description, String
    field :details, GraphQL::Types::JSON, null: false
    field :document_type, String
    field :first_published_at, GraphQL::Types::ISO8601DateTime, null: false
    field :locale, String, null: false
    field :phase, String, null: false
    field :public_updated_at, GraphQL::Types::ISO8601DateTime, null: false
    field :publishing_app, String
    field :publishing_request_id, String
    field :publishing_scheduled_at, GraphQL::Types::ISO8601DateTime
    field :rendering_app, String
    field :scheduled_publishing_delay_seconds, Int
    field :schema_name, String
    field :title, String, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime
    field :withdrawn_notice, WithdrawnNotice

    def withdrawn_notice
      return nil unless object.unpublishing&.withdrawal?

      Presenters::EditionPresenter
        .new(object)
        .present
        .fetch(:withdrawn_notice)
    end

    # Aliased by field methods for fields that are currently presented in the
    # content item, but come from Content Store, so we can't provide them here
    def not_stored_in_publishing_api
      nil
    end

    alias_method :publishing_scheduled_at, :not_stored_in_publishing_api
    alias_method :scheduled_publishing_delay_seconds, :not_stored_in_publishing_api
  end
end
