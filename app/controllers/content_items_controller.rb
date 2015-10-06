class ContentItemsController < ApplicationController
  before_filter :validate_routing_key_fields, only: [:put_live_content_item]

  def put_live_content_item
    response = command_processor.put_content_with_links(content_item.merge(base_path: base_path))
    render status: response.code, json: response.as_json
  end

  def put_draft_content_item
    response = command_processor.put_draft_content_with_links(content_item.merge(base_path: base_path))
    render status: response.code, json: response.as_json
  end

  def publish
    response = command_processor.publish(payload.merge("content_id" => params[:content_id]))
    render status: response.code, json: response.as_json
  end

private
  def command_processor
    CommandProcessor.new(nil)
  end

  def validate_routing_key_fields
    unless [:format, :update_type].all? {|field| content_item[field] =~ /\A[a-z0-9_]+\z/i}
      head :unprocessable_entity
    end
  end
end
