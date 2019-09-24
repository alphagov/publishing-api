module Queries
  LinkablePresenter = Struct.new(:content_id, :title, :publication_state, :base_path, :internal_name)

  class GetLinkables
    def initialize(document_type:)
      @document_type = document_type
    end

    def call
      Rails.cache.fetch ["linkables", document_type, latest_updated_at(document_type)] do
        linkables_query(document_type)
          .map { |result| LinkablePresenter.new(*result) }
      end
    end

  private

    attr_reader :document_type

    def latest_updated_at(document_type)
      non_placeholder = Edition.where(document_type: document_type)
        .maximum("updated_at")
      placeholder = Edition.where(document_type: "placeholder_#{document_type}")
        .maximum("updated_at")
      [non_placeholder, placeholder].compact.max
    end

    def linkables_query(document_type)
      Edition.with_document
        .where(
          document_type: [document_type, "placeholder_#{document_type}"],
          state: %w(published draft),
          "documents.locale": "en",
        )
        .order("documents.content_id ASC")
        .order("CASE editions.state WHEN 'published' THEN 0 ELSE 1 END")
        .pluck(
          "DISTINCT ON (documents.content_id) documents.content_id",
          :title,
          :state,
          :base_path,
          "COALESCE(details->>'internal_name', title)",
        )
    end
  end
end
