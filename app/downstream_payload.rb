class DownstreamPayload
  attr_reader :edition, :payload_version, :draft

  def initialize(edition, payload_version, draft: false)
    @edition = edition
    @payload_version = payload_version
    @draft = draft
  end

  def state
    edition.state
  end

  def base_path
    edition.base_path
  end

  def unpublished?
    edition.unpublished?
  end

  def content_store_action
    return :no_op unless base_path
    return :put unless unpublished?

    case unpublishing.type
    when "vanish" then :delete
    when "substitute" then :no_op
    else :put
    end
  end

  def content_store_payload
    return content_payload unless unpublished?

    case unpublishing.type
    when "redirect" then redirect_payload
    when "gone" then gone_payload
    else content_payload
    end
  end

  def message_queue_payload(update_type)
    Presenters::EditionPresenter.new(
      edition, draft: draft
    ).for_message_queue(update_type || edition.update_type)
  end

private

  def unpublishing
    edition.unpublishing
  end

  def content_payload
    Presenters::EditionPresenter.new(
      edition, draft: draft
    ).for_content_store(payload_version)
  end

  def redirect_payload
    RedirectPresenter.present(
      base_path: base_path,
      publishing_app: edition.publishing_app,
      public_updated_at: unpublishing.created_at,
      redirects: unpublishing.redirects,
    ).merge(payload_version: payload_version)
  end

  def gone_payload
    GonePresenter.present(
      base_path: base_path,
      publishing_app: edition.publishing_app,
      alternative_path: unpublishing.alternative_path,
      explanation: unpublishing.explanation,
    ).merge(payload_version: payload_version)
  end
end
