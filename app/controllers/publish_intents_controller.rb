class PublishIntentsController < ApplicationController
  def create_or_update
    item = content_item.merge(base_path: base_path)
    response = command_processor.put_publish_intent(item)
    render status: response.code, json: response.as_json
  end

  def show
    render json: Query::GetPublishIntent.new(base_path).call
  end

  def destroy
    response = command_processor.delete_publish_intent(base_path: base_path)
    render status: response.code, json: response.as_json
  end

private
  def command_processor
    CommandProcessor.new(nil)
  end
end
