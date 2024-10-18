# frozen_string_literal: true

module Types
  class EditionType < GraphQL::Schema::Object
    field :title, String
  end
end
