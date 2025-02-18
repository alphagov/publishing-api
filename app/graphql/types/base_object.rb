# frozen_string_literal: true

module Types
  class BaseObject < GraphQL::Schema::Object
    ALL_EDITION_COLUMNS = Set.new(%i[
      analytics_identifier
      auth_bypass_ids
      base_path
      content_store
      created_at
      description
      details
      document_id
      document_type
      first_published_at
      id
      last_edited_at
      last_edited_by_editor_id
      major_published_at
      phase
      public_updated_at
      published_at
      publishing_api_first_published_at
      publishing_api_last_edited_at
      publishing_app
      publishing_request_id
      redirects
      rendering_app
      routes
      schema_name
      state
      title
      update_type
      updated_at
      user_facing_version
    ]).freeze

    FIELDS_TO_EDITION_COLUMNS = {
      links: %i[id content_store],
      web_url: :base_path,
    }.freeze

    edge_type_class(Types::BaseEdge)
    connection_type_class(Types::BaseConnection)
    field_class Types::BaseField

    def self.links_field(link_type, graphql_field_type)
      field(link_type.to_sym, graphql_field_type, extras: [:lookahead])

      define_method(link_type.to_sym) do |lookahead:|
        selections = convert_edition_selections(lookahead:)

        dataloader.with(Sources::LinkedToEditionsSource, content_store: object.content_store)
          .load([object, link_type.to_s, selections])
      end
    end

    def self.reverse_links_field(field_name, link_type, graphql_field_type)
      field(field_name.to_sym, graphql_field_type)

      define_method(field_name.to_sym) do
        dataloader.with(Sources::ReverseLinkedToEditionsSource, content_store: object.content_store)
          .load([object, link_type.to_s])
      end
    end

  private

    def convert_edition_selections(lookahead:)
      selections = lookahead.selections.map(&:name)
      mapped_columns = selections.flat_map { FIELDS_TO_EDITION_COLUMNS[_1] }
      ALL_EDITION_COLUMNS & (mapped_columns + selections)
    end
  end
end
