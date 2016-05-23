module Queries
  class GetLinkables
    def initialize(document_type:)
      @document_type = document_type
    end

    def call
      Linkable
        .where(document_type: document_type)
        .includes(:content_item)
        .map { |linkable|
          Presenters::Queries::LinkablePresenter.present(linkable)
        }
    end

  private

    attr_reader :document_type
  end
end
