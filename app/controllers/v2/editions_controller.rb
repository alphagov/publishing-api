module V2
  class EditionsController < ApplicationController
    def index
      query = Queries::KeysetPagination.new(
        Queries::KeysetPagination::GetEditions.new(edition_params),
        pagination_params
      )

      render json: Presenters::KeysetPaginationPresenter.new(
        query, request.original_url,
      ).present
    end

  private

    def edition_params
      params
        .permit(
          :order, :locale, :publishing_app, :per_page,
          :before, :after, document_types: [], fields: [], states: []
        )
    end

    def pagination_params
      {
        per_page: edition_params[:per_page],
        before: edition_params[:before].try(:split, ","),
        after: edition_params[:after].try(:split, ","),
      }
    end
  end
end
