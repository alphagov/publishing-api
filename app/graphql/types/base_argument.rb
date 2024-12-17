# frozen_string_literal: true

module Types
  class BaseArgument < GraphQL::Schema::Argument
    def initialize(*args, camelize: false, **kwargs, &block)
      super
    end
  end
end
