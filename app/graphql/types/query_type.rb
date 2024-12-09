# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    field :edition, EditionTypeOrSubtype, description: "An edition or one of its subtypes" do
      argument :base_path, String
      argument :content_store, String, required: false, default_value: "live"
    end

    def edition(base_path:, content_store:)
      Edition.where(content_store:).find_by(base_path:)
    end
  end
end
