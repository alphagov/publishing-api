module V2
  class ContentItemsController < ApplicationController
    def index
      content_format = params.fetch(:content_format)
      fields = params.fetch(:fields)
      publishing_app = params[:publishing_app]  # can be blank
      render json: Queries::GetContentCollection.new(content_format: content_format,
                                                    fields: fields,
                                                    publishing_app: publishing_app,
                                                    pagination: pagination_params).call
    end

    def show
      render json: Queries::GetContent.call(params[:content_id], params[:locale])
    end

    def put_content
      response = with_event_logging(Commands::V2::PutContent, content_item) do
        Commands::V2::PutContent.call(content_item)
      end

      render status: response.code, json: response
    end

    def publish
      response = with_event_logging(Commands::V2::Publish, content_item) do
        Commands::V2::Publish.call(content_item)
      end

      render status: response.code, json: response
    end

    def discard_draft
      response = with_event_logging(Commands::V2::DiscardDraft, content_item) do
        Commands::V2::DiscardDraft.call(content_item)
      end

      render status: response.code, json: response
    end

  private
    def content_item
      payload.merge(content_id: params[:content_id])
    end

    def pagination_params
      {
        start: params.fetch(:start, 0).to_i,
        count: params.fetch(:count, 50).to_i,
      }
    end
  end
end
