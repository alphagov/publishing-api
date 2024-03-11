# frozen_string_literal: true

module Types
  class RoleType < Types::BaseObject
    description "A role"
    field :people, [PersonType]
    field :body, String
    field :title, String

    def people
      raise "TODO"
    end

    def title
      object.title
    end

    def body
      object.details.dig(:body, 0, :content)
    end
  end
end
