module Queries
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
        scope = Edition.where(
          document_type: [document_type, "placeholder_#{document_type}"]
        )

        edition_ids = Edition
          .from("(#{scope.where(content_store: 'live').to_sql}) AS live")
          .joins("FULL OUTER JOIN (#{scope.where(content_store: 'draft').to_sql}) AS draft ON draft.document_id = live.document_id")
          .select("COALESCE(live.id, draft.id)")

        linkable_values = Edition
          .where(id: edition_ids)
          .with_document
          .includes(:document).pluck(
            :title,
            :content_id,
            :state,
            :base_path,
            "COALESCE(details->>'internal_name', title)"
          )

        linkable_values.map do |fields|
          Hash[%i(title content_id publication_state base_path internal_name).zip(fields)]
        end
      end
    end

  private

    attr_reader :document_type
  end
end
