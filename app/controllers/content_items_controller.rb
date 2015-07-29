class ContentItemsController < ApplicationController
  include URLArbitration

  def put_live_content_item
    with_url_arbitration do
      with_502_suppression do
        draft_content_store.put_content_item(content_item)
      end

      live_response = live_content_store.put_content_item(content_item)

      render json: content_item, content_type: live_response.headers[:content_type]
    end
  end

  def put_draft_content_item
    with_url_arbitration do
      draft_response = with_502_suppression do
        draft_content_store.put_content_item(content_item)
      end

      if draft_response
        render json: content_item, content_type: draft_response.headers[:content_type]
      else
        render json: content_item
      end
    end
  end

private

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

  def content_item
    super.except(:access_limited)
  end
end
