# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    EDITION_TYPES = [Types::EditionType, Types::WorldIndexType].freeze

    EDITION_TYPES.each do |edition_type|
      field :edition, edition_type, description: "An edition" do
        argument :base_path, String
      end
    end

    def edition(base_path:)
      Edition.live.find_by(base_path:)
    end
  end
end
