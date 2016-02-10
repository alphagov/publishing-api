module V2
  class ContentItemsController < ApplicationController
    def index
      content_format = params.fetch(:content_format)
      fields = params.fetch(:fields)
      publishing_app = params[:publishing_app]  # can be blank
      render json: Queries::GetContentCollection.new(content_format: content_format, fields: fields, publishing_app: publishing_app).call
    end

    def show
      render json: Queries::GetContent.call(params[:content_id], params[:locale])
    end

    def put_content
      response = Commands::V2::PutContent.call(content_item)
      render status: response.code, json: response
    end

    def publish
      response = Commands::V2::Publish.call(content_item)
      render status: response.code, json: response
    end

    def discard_draft
      response = Commands::V2::DiscardDraft.call(content_item)
      render status: response.code, json: response
    end

  private
    def content_item
      payload.merge(content_id: params[:content_id])
    end
  end
end
