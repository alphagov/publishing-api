module V2
  class ContentItemsController < ApplicationController
    def show
      render json: Query::GetContent.new(params[:content_id]).call
    end

    def put_content
      response = command_processor.put_content(content_item.merge(content_id: params[:content_id]))
      render status: response.code, json: response.as_json
    end

  private
    def command_processor
      CommandProcessor.new(nil)
    end
  end
end
