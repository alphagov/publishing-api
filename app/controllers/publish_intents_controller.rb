class PublishIntentsController < ApplicationController
  before_filter :parse_content_item, only: [:create_or_update]

  def create_or_update
    response = command_processor.put_publish_intent(content_item.merge(base_path: base_path))
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
