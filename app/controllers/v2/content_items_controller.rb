module V2
  class ContentItemsController < ApplicationController
    def index
      pagination = Pagination.new(query_params)

      results = Queries::GetContentCollection.new(
        document_types:,
        fields: query_params[:fields],
        filters:,
        pagination:,
        search_query: query_params.fetch("q", ""),
        search_in: query_params[:search_in],
      )

      render json: Presenters::ResultsPresenter.new(results, pagination, request.original_url).present
    end

    def linkables
      render json: Queries::GetLinkables.new(
        document_type: query_params.fetch(:document_type),
      ).call
    end

    def host_content
      results = GetHostContentService.new(
        path_params[:content_id],
        query_params[:order],
        query_params[:page],
        query_params[:per_page],
      ).call

      render json: results
    end

    def show
      render json: Queries::GetContent.call(
        path_params[:content_id],
        query_params[:locale],
        version: query_params[:version],
        include_warnings: true,
      )
    end

    def put_content
      response = Commands::V2::PutContent.call(edition)
      render status: response.code, json: response
    end

    def publish
      response = Commands::V2::Publish.call(edition)
      render status: response.code, json: response
    end

    def republish
      response = Commands::V2::Republish.call(edition)
      render status: response.code, json: response
    end

    def unpublish
      response = Commands::V2::Unpublish.call(edition)
      render status: response.code, json: response
    end

    def discard_draft
      response = Commands::V2::DiscardDraft.call(edition)
      render status: response.code, json: response
    end

  private

    def edition
      payload.merge(content_id: path_params[:content_id])
    end

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
        publishing_app:,
        locale: query_params[:locale],
        links: link_filters,
        states: Array(states),
      }
    end

    def link_filters
      {}.tap do |hash|
        query_params.each do |k, v|
          hash[k[5..]] = v if k.start_with?("link_")
        end
      end
    end
  end
end
