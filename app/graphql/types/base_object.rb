# frozen_string_literal: true

module Types
  class BaseObject < GraphQL::Schema::Object
    edge_type_class(Types::BaseEdge)
    connection_type_class(Types::BaseConnection)
    field_class Types::BaseField

    def self.links_field(field_name_and_link_type, graphql_field_type)
      field(field_name_and_link_type.to_sym, graphql_field_type)

      define_method(field_name_and_link_type.to_sym) do
        dataloader.with(Sources::LinkedToEditionsSource, parent_object: object)
          .load(field_name_and_link_type.to_s)
      end
    end
  end
end
