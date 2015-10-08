class PublishIntentsController < ApplicationController
  def show
    render json: Query::GetPublishIntent.new(base_path).call
  end

  def create_or_update
    response = with_event_logging(Command::PutPublishIntent, content_item) do
      Command::PutPublishIntent.call(content_item)
    end

    render status: response.code, json: response.as_json
  end

  def destroy
    response = with_event_logging(Command::DeletePublishIntent, base_path: base_path) do
      Command::DeletePublishIntent.call(base_path: base_path)
    end

    render status: response.code, json: response.as_json
  end

private
  def content_item
    payload.merge(base_path: base_path)
  end
end
