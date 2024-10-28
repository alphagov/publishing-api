# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    field :edition, EditionTypeOrSubtype, description: "An edition or one of its subtypes" do
      argument :base_path, String
    end

    def edition(base_path:)
      Edition.live.find_by(base_path:)
    end
  end
end
