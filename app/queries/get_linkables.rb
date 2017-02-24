module Queries
  LinkablePresenter = Struct.new(:title, :content_id, :publication_state, :base_path, :internal_name)

  class GetLinkables
    def initialize(document_type:)
      @document_type = document_type
    end

    def call
      latest_updated_at = Edition
        .where(document_type: [document_type, "placeholder_#{document_type}"])
        .order('updated_at DESC')
        .limit(1)
        .pluck(:updated_at)
        .last

      Rails.cache.fetch ["linkables", document_type, latest_updated_at] do
        edition_ids = Queries::GetEditionIdsWithFallbacks.(
          Edition.with_document.distinct.where(
            document_type: [document_type, "placeholder_#{document_type}"]
          ).pluck('documents.content_id'),
          state_fallback_order: [:published, :draft]
        )

        Edition.with_document
          .where(id: edition_ids)
          .pluck(:title, :content_id, :state, :base_path, "COALESCE(details->>'internal_name', title)")
          .map do |(title, content_id, state, base_path, internal_name)|
            LinkablePresenter.new(
              title,
              content_id,
              state,
              base_path,
              internal_name,
            )
          end
      end
    end

  private

    attr_reader :document_type
  end
end
