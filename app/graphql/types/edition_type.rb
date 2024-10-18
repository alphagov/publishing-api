# frozen_string_literal: true

module Types
  class EditionType < Types::BaseObject
    field :title, String

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
