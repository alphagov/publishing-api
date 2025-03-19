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

      selections[:editions].append(:document_type)

      if lookahead.selects?(:links)
        if lookahead.selection(:links).selects?(:available_translations)
          selections[:editions].append(:state)
        end

        (selections[:documents] ||= []).append(:content_id, :locale)
      end

      Edition
        .joins(selections[:documents].present? && :document)
        .left_joins(selections[:unpublishings].present? && :unpublishing)
        .select(selections).where(content_store:).find_by(base_path:)
    end
  end
end
