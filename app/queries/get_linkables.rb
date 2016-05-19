module Queries
  class GetLinkables
    def initialize(document_type:)
      @document_type = document_type
    end

    def call
      Linkable
        .where(document_type: [document_type, "placeholder_#{document_type}"])
        .includes(:content_item)
        .pluck(:content_id, :state, :title, :base_path, "content_items.details->>'internal_name' as internal_name")
        .map { |linkable_data|
          Presenters::Queries::LinkablePresenter.present(*linkable_data)
        }
    end

  private

    attr_reader :document_type
  end
end
