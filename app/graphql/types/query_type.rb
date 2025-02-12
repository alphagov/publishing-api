# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    field :edition, EditionTypeOrSubtype, description: "An edition or one of its subtypes" do
      argument :base_path, String
      argument :content_store, String, required: false, default_value: "live"

      extras [:lookahead]
    end

    def edition(base_path:, content_store:, lookahead:)
      selections = GraphqlSelections.with_edition_fields(
        lookahead.selections.map(&:name),
      )

      selections.insert(:editions, %i[document_type])

      if lookahead.selects?(:links)
        if lookahead.selections.find { _1.name == :links }.selects?(:available_translations)
          selections.insert(:editions, %i[state])
        end

        selections.insert(:documents, %i[content_id locale])
      end

      if selections.selects_from_table?(:documents)
        Edition
          .joins(:document)
          .select(selections.to_select_args).where(content_store:).find_by(base_path:)
      else
        Edition
          .select(selections.to_select_args).where(content_store:).find_by(base_path:)
      end
    end
  end
end
