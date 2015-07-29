module URLArbitration
  def with_url_arbitration(&block)
    url_arbiter.reserve_path(
      base_path,
      publishing_app: content_item[:publishing_app]
    )

    block.call
  rescue GOVUK::Client::Errors::UnprocessableEntity => e
    render json: e.response, status: 422
  rescue GOVUK::Client::Errors::Conflict => e
    render json: e.response, status: 409
  end

  def url_arbiter
    PublishingAPI.services(:url_arbiter)
  end
end
