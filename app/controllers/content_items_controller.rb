class ContentItemsController < ApplicationController
  include URLArbitration

  before_filter :parse_content_item
  before_filter :validate_routing_key_fields, only: [:put_live_content_item]
  rescue_from GdsApi::HTTPClientError, with: :propagate_error
  rescue_from UrlArbitrationError, with: :propagate_error

  def put_live_content_item
    command_processor.put_content_with_links
    render json: content_item
  end

  def put_draft_content_item
    command_processor.put_draft_content_with_links
    render json: content_item
  end

private
  def command_processor
    CommandProcessor.new(base_path, nil, content_item)
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

  def validate_routing_key_fields
    unless [:format, :update_type].all? {|field| content_item[field] =~ /\A[a-z0-9_]+\z/i}
      head :unprocessable_entity
    end
  end
end
