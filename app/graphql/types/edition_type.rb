# frozen_string_literal: true

module Types
  class EditionType < GraphQL::Schema::Object
    field :content_id, String
    field :title, String
    field :details, String
  end
end
