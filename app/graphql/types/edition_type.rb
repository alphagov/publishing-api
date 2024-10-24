# frozen_string_literal: true

module Types
  class EditionType < Types::BaseObject
    class WithdrawnNotice < Types::BaseObject
      field :explanation, String
      field :withdrawn_at, GraphQL::Types::ISO8601DateTime
    end

    field :analytics_identifier, String # format: all.jsonnet, definition: publishing_api_base.jsonnet
    field :base_path, String # format: default_format.jsonnet, definition: paths.jsonnet
    field :content_id, ID # format: frontend_content_id in default_format.jsonnet?, definition: ?
    field :description, String # format: default_format.jsonnet, definition: publishing_api_base.jsonnet
    # TODO: make details a more realistic type
    field :details, String, null: false # format: default_format.jsonnet and all.jsonnet, definition: publishing_api_base.jsonnet
    field :document_type, String # defined in individual formats
    field :first_published_at, GraphQL::Types::ISO8601DateTime, null: false # format: [publisher/frontend/notification].jsonnet, definition: publishing_api_base.jsonnet
    # TODO: work out how to retrieve the links returned in the content item
    field :links, [String], null: false # format: default_format.jsonnet using base_links.jsonnet?, definition: base_links.jsonnet?
    field :locale, String, null: false # format: all.jsonnet, definition: locale.jsonnet
    field :phase, String, null: false # format: all.jsonnet, definition: all.jsonnet
    field :public_updated_at, GraphQL::Types::ISO8601DateTime, null: false # format: [publisher/frontend/notification].jsonnet, definition: publishing_api_base.jsonnet
    field :publishing_app, String # format: all.jsonnet, definition: publishing_app.jsonnet
    field :publishing_request_id, String # format: publishing_api_out.jsonnet, definition: publishing_api_base.jsonnet
    field :publishing_scheduled_at, GraphQL::Types::ISO8601DateTime # format: frontend.jsonnet, definition: publishing_api_base.jsonnet
    field :rendering_app, String # format: default_format.jsonnet, definition: rendering_app.jsonnet
    field :scheduled_publishing_delay_seconds, Int # format: frontend.jsonnet, definition: publishing_api_base.jsonnet
    field :schema_name, String # derived from file name of schema in regenerate_schemas.rake
    field :title, String, null: false # format: default_format.jsonnet, definition: publishing_api_base.jsonnet
    field :updated_at, GraphQL::Types::ISO8601DateTime # format: frontend.jsonnet, definition: frontend.jsonnet
    # TODO: make this return an empty object when corresponding method does
    field :withdrawn_notice, WithdrawnNotice # format: publishing_api_out.jsonnet, definition: publishing_api_base.jsonnet

    def withdrawn_notice
      Presenters::EditionPresenter
        .new(object)
        .present
        .fetch(:withdrawn_notice, {})
    end

    # Aliased by field methods for fields that are currently presented in the
    # content item, but are not available via the Publishing API.
    def not_stored_in_publishing_api
      nil
    end

    alias_method :publishing_scheduled_at, :not_stored_in_publishing_api
    alias_method :scheduled_publishing_delay_seconds, :not_stored_in_publishing_api

    class << self
      def visible?(context)
        return unless super

        base_path_argument = base_path_argument(context)

        if name == "Types::EditionType"
          descendants.none? { |descendant| base_path_argument == descendant.base_path }
        else
          base_path_argument == base_path
        end
      end

    private

      def base_path_argument(context)
        context
          .query
          .lookahead
          .ast_nodes.first
          .selections.first
          .arguments
          .find { |argument| argument.name == "basePath" }
          &.value
      end
    end
  end
end
