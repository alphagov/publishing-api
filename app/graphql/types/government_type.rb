# frozen_string_literal: true

module Types
  class GovernmentType < Types::EditionType
    description "A government"
    field :current, Boolean
    field :started_on, String
    field :ended_on, String

    def current
      object.details[:current]
    end

    def started_on
      object.details[:started_on]
    end

    def ended_on
      object.details[:ended_on]
    end
  end
end
