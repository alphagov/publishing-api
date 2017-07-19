module V2
  class EditionsController < ApplicationController
    def index
      query = Queries::KeysetPagination.new(
        Queries::KeysetPagination::GetEditions.new(
          fields: query_params[:fields],
          filters: filters,
        ),
        **pagination_params
      )

      render json: Presenters::KeysetPaginationPresenter.new(
        query, request.original_url,
      ).present
    end

  private

    def publishing_app
      query_params[:publishing_app]
    end

    def states
      query_params[:states]
    end

    def document_types
      query_params[:document_type] || query_params[:content_format] || []
    end

    def filters
      {
        publishing_app: publishing_app,
        locale: query_params[:locale],
        states: Array(states),
      }
    end

    def pagination_params
      KeysetPaginationParameters.from_query(
        params: query_params,
        default_order: "updated_at",
        table: "editions",
      )
    end
  end
end
