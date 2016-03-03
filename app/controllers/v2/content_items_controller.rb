module V2
  class ContentItemsController < ApplicationController
    def index
      format = query_params.fetch(:content_format) { query_params.fetch(:format) }

      render json: Queries::GetContentCollection.new(
        content_format: format,
        fields: query_params.fetch(:fields),
        publishing_app: publishing_app,
        locale: query_params[:locale],
      ).call
    end

    def linkables
      # Base path is returned to facilitate rummager indexing.
      # This can be removed once link updates are picked up by rummager from the message bus.
      render json: Queries::GetContentCollection.new(
        content_format: query_params.fetch(:format),
        fields: %w(
          title
          content_id
          publication_state
          base_path
          internal_name
        ),
      ).call
    end

    def show
      render json: Queries::GetContent.call(path_params[:content_id], query_params[:locale])
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
      payload.merge(content_id: path_params[:content_id])
    end

    def publishing_app
      unless current_user.has_permission?('view_all')
        current_user.app_name
      end
    end
  end
end
