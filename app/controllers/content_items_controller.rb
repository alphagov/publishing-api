class ContentItemsController < ApplicationController
  def live_content_item
    response = url_arbiter.reserve_path(
      base_path,
      publishing_app: content_item[:publishing_app]
    )

    render json: {created: "ok"}
  rescue GOVUK::Client::Errors::UnprocessableEntity => e
    render json: e.response, status: 422
  rescue GOVUK::Client::Errors::Conflict => e
    render json: e.response, status: 409
  end

private

  def url_arbiter
    PublishingAPI.services(:url_arbiter)
  end
end
