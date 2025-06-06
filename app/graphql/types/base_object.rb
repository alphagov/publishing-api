# frozen_string_literal: true

module Types
  class BaseObject < GraphQL::Schema::Object
    edge_type_class(Types::BaseEdge)
    connection_type_class(Types::BaseConnection)
    field_class Types::BaseField

    def self.links_field(link_type, graphql_field_type)
      field(link_type.to_sym, graphql_field_type)

      define_method(link_type.to_sym) do
        dataloader.with(
          Sources::LinkedToEditionsSource,
          content_store: object.content_store,
          locale: context[:root_edition].locale,
        )
          .load([object, link_type.to_s])
      end
    end

    def self.reverse_links_field(field_name, link_type, graphql_field_type)
      field(field_name.to_sym, graphql_field_type)

      define_method(field_name.to_sym) do
        dataloader.with(
          Sources::ReverseLinkedToEditionsSource,
          content_store: object.content_store,
          locale: context[:root_edition].locale,
        )
          .load([object, link_type.to_s])
      end
    end
  end
end
