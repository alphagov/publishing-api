class ContentItemsController < ApplicationController
  before_filter :validate_routing_key_fields, only: [:put_live_content_item]

  def put_live_content_item
    response = with_event_logging(Commands::PutContentWithLinks, content_item) do
      Commands::PutContentWithLinks.call(content_item)
    end

    render status: response.code, json: response
  end

  def put_draft_content_item
    response = with_event_logging(Commands::PutDraftContentWithLinks, content_item) do
      Commands::PutDraftContentWithLinks.call(content_item)
    end

    render status: response.code, json: response
  end

private
  def validate_routing_key_fields
    unless [:format, :update_type].all? {|field| content_item[field] =~ /\A[a-z0-9_]+\z/i}
      head :unprocessable_entity
    end
  end

  def content_item
    payload.merge(base_path: base_path)
  end
end
