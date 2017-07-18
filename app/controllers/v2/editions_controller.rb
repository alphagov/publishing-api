module V2
  class EditionsController < ApplicationController
    def index
      query = Queries::KeysetPagination.new(
        Queries::GetEditions.new(
          fields: query_params[:fields],
          filters: filters,
        ).call,
        key: { updated_at: "editions.updated_at", id: "editions.id" },
        **pagination_params
      )

      render json: Presenters::KeysetPaginationPresenter.new(
        query, request.original_url,
        present_record_filter: -> (record) {
          record.except("id", "document_id")
        }
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
      page = query_params[:page]
      if page.present?
        if page.first == "-"
          page = page[1..page.length]
          order = :desc
        else
          order = :asc
        end
      end

      {
        page: page.try(:split, ","),
        count: query_params[:count],
        order: order,
      }
    end
  end
end
