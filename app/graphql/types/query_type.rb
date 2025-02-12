# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    field :edition, EditionTypeOrSubtype, description: "An edition or one of its subtypes" do
      argument :base_path, String
      argument :content_store, String, required: false, default_value: "live"

      extras [:lookahead]
    end

    def edition(base_path:, content_store:, lookahead:)
      selections = {}
      selections[:editions] = convert_edition_selections(lookahead:)

      selections[:editions] << :document_type

      if lookahead.selects?(:links)
        if lookahead.selections.find { _1.name == :links }.selects?(:available_translations)
          selections[:editions] << :state
        end

        selections[:documents] = %i[content_id locale]
      end

      selections[:editions] = selections[:editions].to_a

      if lookahead.selects?(:links)
        Edition
          .joins(:document)
          .select(selections).where(content_store:).find_by(base_path:)
      else
        Edition
          .select(selections).where(content_store:).find_by(base_path:)
      end
    end
  end
end
