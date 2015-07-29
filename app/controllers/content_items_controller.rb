class ContentItemsController < ApplicationController
  def live_content_item
    url_arbiter.reserve_path(
      base_path,
      publishing_app: content_item[:publishing_app]
    )

    draft_content_store.put_content_item(content_item)
    live_content_store.put_content_item(content_item)

    render json: content_item
  rescue GOVUK::Client::Errors::UnprocessableEntity => e
    render json: e.response, status: 422
  rescue GOVUK::Client::Errors::Conflict => e
    render json: e.response, status: 409
  end

private

  def url_arbiter
    PublishingAPI.services(:url_arbiter)
  end

  def draft_content_store
    PublishingAPI.services(:draft_content_store)
  end

  def live_content_store
    PublishingAPI.services(:live_content_store)
  end
end
