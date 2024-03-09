# frozen_string_literal: true

module Types
  class PersonType < Types::BaseObject
    description "A person"
    field :full_name, String
    field :roles, [RoleType]

    def full_name
      object.details[:full_name]
    end

    def roles
      raise "TODO"
    end
  end
end
