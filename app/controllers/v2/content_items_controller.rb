module V2
  class ContentItemsController < ApplicationController
    def index
      doc_types = query_params.fetch(:document_type) { query_params.fetch(:content_format) }
      pagination = Pagination.new(query_params)

      results = Queries::GetContentCollection.new(
        document_types: doc_types,
        fields: query_params[:fields],
        filters: filters,
        pagination: pagination,
        search_query: query_params.fetch("q", "")
      )

      render json: Presenters::ResultsPresenter.new(results, pagination, request.original_url).present
    end

    def linkables
      render json: Queries::GetLinkables.new(
        document_type: query_params.fetch(:document_type),
      ).call
    end

    def show
      ensure_valid_content_id

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

    def filters
      {
        publishing_app: publishing_app,
        locale: query_params[:locale],
        links: link_filters,
        states: Array(states),
      }
    end

    def link_filters
      {}.tap do |hash|
        query_params.each do |k, v|
          hash[k[5..-1]] = v if k.start_with?("link_")
        end
      end
    end
  end
end
