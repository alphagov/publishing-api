module Queries
  LinkablePresenter = Struct.new(:title, :content_id, :publication_state, :base_path, :internal_name) do
    def self.from_hash(hash)
      fields = [
        hash[:title],
        hash[:content_id],
        hash[:state],
        hash[:base_path],
        hash[:details].fetch(:internal_name, hash[:title]),
      ]
      new(*fields)
    end
  end

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

        Edition.where(id: edition_ids).map do |edition|
          LinkablePresenter.from_hash(edition.to_h.deep_symbolize_keys)
        end
      end
    end

  private

    attr_reader :document_type
  end
end
