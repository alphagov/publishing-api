module V2
  class ContentItemsController < ApplicationController
    def index
      content_format = params.fetch(:content_format)
      fields = params.fetch(:fields)
      locale = params[:locale]
      render json: Queries::GetContentCollection.new(
        content_format: content_format,
        fields: fields,
        publishing_app: publishing_app,
        locale: locale,
      ).call
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

    def publishing_app
      unless current_user.has_permission?('view_all')
        current_user.app_name
      end
    end
  end
end
