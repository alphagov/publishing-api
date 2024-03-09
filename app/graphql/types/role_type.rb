# frozen_string_literal: true

module Types
  class RoleType < Types::BaseObject
    description "A role"
    field :people, [PersonType]
    field :body, String

    def people
      raise "TODO"
    end

    def body
      object.details[:body]
    end
  end
end
