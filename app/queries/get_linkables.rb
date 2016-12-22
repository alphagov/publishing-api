module Queries
  LinkablePresenter = Struct.new(:title, :content_id, :publication_state, :base_path, :internal_name) do
    def self.from_hash(hash)
      fields = [
        hash["title"],
        hash["content_id"],
        hash["state"],
        hash["base_path"],
        hash["details"].fetch("internal_name", hash['title']),
      ]
      new(*fields)
    end
  end

  class GetLinkables
    def initialize(document_type:)
      @document_type = document_type
    end

    def call
      latest_updated_at = ContentItem
        .where(document_type: [document_type, "placeholder_#{document_type}"])
        .order('updated_at DESC')
        .limit(1)
        .pluck(:updated_at)
        .last

      Rails.cache.fetch ["linkables", document_type, latest_updated_at] do
        Queries::GetWebContentItems.(
          Queries::GetContentItemIdsWithFallbacks.(
            ContentItem.distinct.joins(:document).where(
              document_type: [document_type, "placeholder_#{document_type}"]
            ).pluck('documents.content_id'),
            state_fallback_order: [:published, :draft]
          ),
          LinkablePresenter
        )
      end
    end

  private

    attr_reader :document_type
  end
end
