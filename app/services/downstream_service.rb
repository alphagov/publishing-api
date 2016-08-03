module DownstreamService
  def self.update_live_content_store(downstream_payload)
    if %w(published unpublished).exclude?(downstream_payload.state)
      message = "Can only send published and unpublished items to live content store"
      raise DownstreamInvariantError.new(message)
    end

    case downstream_payload.content_store_action
    when :put
      Adapters::ContentStore.put_content_item(downstream_payload.base_path, downstream_payload.content_store_payload)
    when :delete
      Adapters::ContentStore.delete_content_item(downstream_payload.base_path)
    end
  end

  def self.update_draft_content_store(downstream_payload)
    if %w(draft published unpublished).exclude?(downstream_payload.state)
      message = "Can only send draft, published and unpublished items to draft content store"
      raise DownstreamInvariantError.new(message)
    end

    case downstream_payload.content_store_action
    when :put
      Adapters::DraftContentStore.put_content_item(downstream_payload.base_path, downstream_payload.content_store_payload)
    when :delete
      Adapters::DraftContentStore.delete_content_item(downstream_payload.base_path)
    end
  end

  def self.broadcast_to_message_queue(downstream_payload, update_type)
    if downstream_payload.state != "published"
      message = "Can only send published items to the message queue"
      raise DownstreamInvariantError.new(message)
    end

    payload = downstream_payload.message_queue_payload(update_type)
    PublishingAPI.service(:queue_publisher).send_message(payload)
  end

  def self.discard_from_draft_content_store(base_path)
    return unless base_path
    if discard_draft_base_path_conflict?(base_path)
      message = "Cannot discard '#{base_path}' as there is an item occupying that base path"
      raise DiscardDraftBasePathConflictError.new(message)
    end
    Adapters::DraftContentStore.delete_content_item(base_path)
  end

  def self.discard_draft_base_path_conflict?(base_path)
    return false unless base_path
    ContentItemFilter.filter(
      base_path: base_path,
      state: %w(draft published unpublished),
    ).exists?
  end
end
