# frozen_string_literal: true

module Types
  class QueryType
    class EditionTypeOrSubtype < Types::BaseUnion
      EDITION_TYPES = [Types::EditionType, Types::WorldIndexType].freeze

      possible_types(*EDITION_TYPES)

      class << self
        def resolve_type(_object, context)
          base_path_argument = base_path_argument(context)

          matching_edition_subtype = Types::EditionType.descendants.find do |edition_subtype|
            base_path_argument == edition_subtype.base_path
          end

          matching_edition_subtype || Types::EditionType
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
end
