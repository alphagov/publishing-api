class DownstreamMediator
  attr_reader :web_content_item, :base_path, :payload_version

  def initialize(web_content_item: nil, base_path: nil, payload_version:)
    @web_content_item = web_content_item
    @base_path = base_path
    @payload_version = payload_version
  end

  def send_to_live_content_store
    send_to_content_store(Adapters::ContentStore)
  end

  def send_to_draft_content_store
    send_to_draft_content_store(Adapters::DraftContentStore)
  end

  def delete_from_draft_content_store
    Adapters::DraftContentStore.delete_content_item(base_path)
  end

  def broadcast_to_message_queue(update_type)
    payload = Presenters::MessageQueuePresenter.present(
      web_content_item,
      state_fallback_order: [:published],
      update_type: update_type,
    )
    PublishingAPI.service(:queue_publisher).send_message(payload)
  end

private

  def unpublishing
    @unpublishing ||= Unpublishing.find_by!(content_item_id: web_content_item.id)
  end

  def send_to_content_store(content_store)
    if web_content_item.state == "unpublished"
      case unpublishing.type
      when "withdrawal"
        send_content_to_content_store(content_store)
      when "redirect"
        send_redirect_to_content_store(content_store)
      when "gone"
        send_gone_to_content_store(content_store)
      when "vanish"
        content_store.delete_content_item(web_content_item.base_path)
      else
        raise RuntimeError.new "Unexpected unpublishing type of '#{unpublishing.type}'"
      end
    else
      send_content_to_content_store(content_store)
    end
  end

  def send_content_to_content_store(content_store)
    payload = Presenters::ContentStorePresenter.present(
      web_content_item,
      payload_version,
      state_fallback_order: content_store::DEPENDENCY_FALLBACK_ORDER
    )
    content_store.put_content_item(web_content_item.base_path, payload)
  end

  def send_redirect_to_content_store(content_store)
    payload = RedirectPresenter.present(
      base_path: web_content_item.base_path,
      publishing_app: web_content_item.publishing_app,
      destination: unpublishing.alternative_path,
      public_updated_at: unpublishing.created_at,
    )
    payload.merge!(payload_version: payload_version)
    content_store.put_content_item(web_content_item.base_path, payload)
  end

  def send_gone_to_content_store(content_store)
    payload = GonePresenter.present(
      base_path: web_content_item.base_path,
      publishing_app: web_content_item.publishing_app,
      alternative_path: unpublishing.alternative_path,
      explanation: unpublishing.explanation,
    )
    payload.merge!(payload_version: payload_version)
    content_store.put_content_item(web_content_item.base_path, payload)
  end
end
