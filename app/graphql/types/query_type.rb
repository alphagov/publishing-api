# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    field :edition, EditionTypeOrSubtype, description: "An edition or one of its subtypes" do
      argument :base_path, String
      argument :content_store, String, required: false, default_value: "live"

      extras [:lookahead]
    end

    def edition(base_path:, content_store:, lookahead:)
      selections = GraphqlSelections.with_root_edition_fields(
        lookahead.selections.map(&:name),
      )

      if lookahead.selection(:links)&.selects?(:available_translations)
        selections.insert(:editions, %i[state])
      end

      Edition
        .joins(selections.selects_from_table?(:documents) && :document)
        .left_joins(selections.selects_from_table?(:unpublishings) && :unpublishing)
        .select(selections.to_h).where(content_store:).find_by(base_path:)
    end
  end
end
