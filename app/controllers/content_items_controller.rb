class ContentItemsController < ApplicationController

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

  def validate_routing_key_fields
    unless [:format, :update_type].all? {|field| content_item[field] =~ /\A[a-z0-9_]+\z/i}
      head :unprocessable_entity
    end
  end
end
