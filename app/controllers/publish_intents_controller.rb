class PublishIntentsController < ApplicationController
  def show
    render json: Queries::GetPublishIntent.call(base_path)
  end

  def create_or_update
    response = with_event_logging(Commands::PutPublishIntent, content_item) do
      Commands::PutPublishIntent.call(content_item)
    end

    render status: response.code, json: response
  end

  def destroy
    response = with_event_logging(Commands::DeletePublishIntent, base_path: base_path) do
      Commands::DeletePublishIntent.call(base_path: base_path)
    end

    render status: response.code, json: response
  end

private
  def content_item
    payload.merge(base_path: base_path)
  end
end
