module V2
  class EditionsController < ApplicationController
    def index
      query = Queries::KeysetPagination.new(
        Queries::GetEditions.new(
          fields: query_params[:fields],
          filters: filters,
        ).call,
        **pagination_params
      )

      render json: Presenters::GetEditionsPresenter.present(
        query, request.original_url,
      )
    end

  private

    DEFAULT_PAGINATION_KEY = {
      updated_at: "editions.updated_at",
      id: "editions.id"
    }.freeze

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

    def pagination_key
      return DEFAULT_PAGINATION_KEY unless query_params[:key]

      key = query_params[:key]
      key = key[1..key.length] if key.first == "-"

      key.split(",").each_with_object({}) do |field, hash|
        hash[field] = "editions.#{field}"
      end
    end

    def pagination_order
      return :asc unless query_params[:key]
      query_params[:key].first == "-" ? :desc : :asc
    end

    def pagination_params
      {
        key: pagination_key,
        page: query_params[:page].try(:split, ","),
        count: query_params[:count],
        order: pagination_order,
      }
    end
  end
end
