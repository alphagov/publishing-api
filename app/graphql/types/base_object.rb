# frozen_string_literal: true

module Types
  class BaseObject < GraphQL::Schema::Object
    edge_type_class(Types::BaseEdge)
    connection_type_class(Types::BaseConnection)
    field_class Types::BaseField

    def self.links_field(link_type, graphql_field_type)
      field(link_type.to_sym, graphql_field_type, extras: [:lookahead])

      define_method(link_type.to_sym) do |lookahead:|
        attributes = convert_edition_selections(lookahead:, table_name: "editions")

        attributes << :"documents.content_id"

        if lookahead.selects?(:links)
          attributes << :"editions.id"
          attributes << :"editions.content_store"
        end

        dataloader.with(Sources::LinkedToEditionsSource, content_store: object.content_store)
          .load([object, link_type.to_s, attributes])
      end
    end

    def self.reverse_links_field(field_name, link_type, graphql_field_type)
      field(field_name.to_sym, graphql_field_type, extras: [:lookahead])

      define_method(field_name.to_sym) do |lookahead:|
        attributes = convert_edition_selections(lookahead:, table_name: "editions")

        attributes << :"documents.content_id"

        if lookahead.selects?(:links)
          attributes << :"editions.id"
          attributes << :"editions.content_store"
        end

        dataloader.with(Sources::ReverseLinkedToEditionsSource, content_store: object.content_store)
          .load([object, link_type.to_s, attributes])
      end
    end

  private

    def convert_edition_selections(lookahead:, table_name: nil)
      selections = lookahead.selections.map(&:name)
      mapped_columns = selections.map { CONTENT_ITEM_FIELDS_TO_EDITION_COLUMNS[_1] }
      columns = ALL_EDITION_COLUMNS & (mapped_columns + selections)

      return columns if table_name.nil?

      columns.map { :"editions.#{_1}" }
    end
  end
end
