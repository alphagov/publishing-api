class DownstreamPayload
  attr_reader :web_content_item, :payload_version, :state_fallback_order

  def initialize(web_content_item, payload_version, state_fallback_order)
    @web_content_item = web_content_item
    @payload_version = payload_version
    @state_fallback_order = state_fallback_order
  end

  def state
    web_content_item.state
  end

  def base_path
    web_content_item.base_path
  end

  def unpublished?
    state == "unpublished"
  end

  def content_store_action
    return :no_op unless web_content_item.base_path
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
    Presenters::MessageQueuePresenter.present(
      downstream_presenter,
      update_type: update_type || web_content_item.update_type,
    )
  end

private

  def unpublishing
    @unpublishing ||= Unpublishing.find_by!(content_item_id: web_content_item.id)
  end

  def content_payload
    Presenters::ContentStorePresenter.present(
      downstream_presenter,
      payload_version
    )
  end

  def redirect_payload
    payload = RedirectPresenter.present(
      base_path: web_content_item.base_path,
      publishing_app: web_content_item.publishing_app,
      destination: unpublishing.alternative_path,
      public_updated_at: unpublishing.created_at,
    )
    payload.merge(payload_version: payload_version)
  end

  def gone_payload
    payload = GonePresenter.present(
      base_path: web_content_item.base_path,
      publishing_app: web_content_item.publishing_app,
      alternative_path: unpublishing.alternative_path,
      explanation: unpublishing.explanation,
    )
    payload.merge(payload_version: payload_version)
  end

  def downstream_presenter
    @downstream_presenter ||= Presenters::DownstreamPresenter.new(
      web_content_item,
      nil,
      state_fallback_order: state_fallback_order,
    )
  end
end
