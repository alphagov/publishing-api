# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    field :edition, EditionTypeOrSubtype, description: "An edition or one of its subtypes" do
      argument :base_path, String
      argument :content_store, String, required: false, default_value: "live"

      extras [:lookahead]
    end

    def edition(base_path:, content_store:, lookahead:)
      all_selections = lookahead.selections.map(&:name)

      all_selections.delete(:links)

      attributes = all_selections
      attributes += %i{id document_type content_store document_id}
      # id for edition link queries,
      # document_type for EditionTypeOrSubtype
      # content_store for BaseObject#links_field #reverse_links_field
      # document_id for getting Document and its content_id

      Edition.select(attributes).where(content_store:).find_by(base_path:)
    end
  end
end
