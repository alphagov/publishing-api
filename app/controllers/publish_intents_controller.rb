class PublishIntentsController < ApplicationController
  include URLArbitration

  before_filter :parse_content_item, only: [:create_or_update]
  rescue_from GdsApi::HTTPClientError, with: :propagate_error
  rescue_from UrlArbitrationError, with: :propagate_error

  def create_or_update
    command_processor.put_publish_intent
    render json: content_item
  end

  def show
    render json: Query::GetPublishIntent.new(base_path).call
  end

  def destroy
    command_processor.delete_publish_intent
    render json: {}
  end

private

  def command_processor
    CommandProcessor.new(base_path, nil, content_item || {})
  end

  def propagate_error(exception)
    render status: exception.code, json: exception.error_details
  end
end
