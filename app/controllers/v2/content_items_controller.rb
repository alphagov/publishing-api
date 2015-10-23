module V2
  class ContentItemsController < ApplicationController
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

  private
    def content_item
      payload.merge(content_id: params[:content_id])
    end
  end
end
