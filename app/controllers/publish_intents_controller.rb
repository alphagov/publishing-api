class PublishIntentsController < ApplicationController
  include URLArbitration

  before_filter :parse_content_item, only: [:create_or_update]
  rescue_from GdsApi::HTTPClientError, with: :propagate_error
  rescue_from UrlArbitrationError, with: :propagate_error

  def create_or_update
    event = EventLogger.new.log('PutPublishIntent', nil, content_item.merge("base_path" => base_path))
    Command::PutPublishIntent.new(event).call
    render json: content_item
  end

  def show
    render json: Query::GetPublishIntent.new(base_path).call
  end

  def destroy
    event = EventLogger.new.log('DeletePublishIntent', nil, {"base_path" => base_path})
    Command::DeletePublishIntent.new(event).call
    render json: {}
  end

private

  def propagate_error(exception)
    render status: exception.code, json: exception.error_details
  end
end
