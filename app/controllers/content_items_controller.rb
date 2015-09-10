class ContentItemsController < ApplicationController
  include URLArbitration

  before_filter :parse_content_item
  before_filter :validate_routing_key_fields, only: [:put_live_content_item]
  rescue_from GdsApi::HTTPClientError, with: :propagate_error
  rescue_from UrlArbitrationError, with: :propagate_error

  def put_live_content_item
    event = event_logger.log('PutContentWithLinks', nil, content_item.merge("base_path" => base_path))
    Command::PutContentWithLinks.new(event).call
    render json: content_item
  end

  def put_draft_content_item
    event = event_logger.log('PutDraftContentWithLinks', nil, content_item.merge("base_path" => base_path))
    Command::PutDraftContentWithLinks.new(event).call
    render json: content_item
  end

private
  def event_logger
    EventLogger.new
  end

  def propagate_error(exception)
    render status: exception.code, json: exception.error_details
  end

  def with_502_suppression(&block)
    block.call
  rescue GdsApi::HTTPServerError => e
    unless e.code == 502 && ENV["SUPPRESS_DRAFT_STORE_502_ERROR"]
      raise e
    end
  end

  def draft_content_store
    PublishingAPI.services(:draft_content_store)
  end

  def live_content_store
    PublishingAPI.services(:live_content_store)
  end

  def queue_publisher
    PublishingAPI.services(:queue_publisher)
  end

  def content_item_without_access_limiting
    @content_item_without_access_limiting ||= content_item.except(:access_limited)
  end

  def content_item_with_base_path
    content_item_without_access_limiting.merge(base_path: base_path)
  end

  def validate_routing_key_fields
    unless [:format, :update_type].all? {|field| content_item[field] =~ /\A[a-z0-9_]+\z/i}
      head :unprocessable_entity
    end
  end
end
