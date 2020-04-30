module DownstreamService
  def self.update_live_content_store(downstream_payload)
    if %w[published unpublished].exclude?(downstream_payload.state)
      message = "Can only send published and unpublished items to live content store"
      raise DownstreamInvalidStateError.new(message)
    end

    case downstream_payload.content_store_action
    when :put
      Adapters::ContentStore.put_content_item(downstream_payload.base_path, downstream_payload.content_store_payload)
    when :delete
      Adapters::ContentStore.delete_content_item(downstream_payload.base_path)
    end
  end

  def self.update_draft_content_store(downstream_payload)
    if %w[draft published unpublished].exclude?(downstream_payload.state)
      message = "Can only send draft, published and unpublished items to draft content store"
      raise DownstreamInvalidStateError.new(message)
    end
    if downstream_payload.state != "draft" && draft_at_base_path?(downstream_payload.base_path)
      message = "Can't send #{downstream_payload.state} item to draft content store, as there is a draft occupying the same base path"
      raise DownstreamDraftExistsError.new(message)
    end

    case downstream_payload.content_store_action
    when :put
      Adapters::DraftContentStore.put_content_item(downstream_payload.base_path, downstream_payload.content_store_payload)
    when :delete
      Adapters::DraftContentStore.delete_content_item(downstream_payload.base_path)
    end
  end

  def self.broadcast_to_message_queue(downstream_payload, event_type)
    unless %w[unpublished published].include?(downstream_payload.state)
      raise DownstreamInvalidStateError.new(
        "Can only send published or unpublished items to the message queue",
      )
    end

    payload = downstream_payload.message_queue_payload
    PublishingAPI.service(:queue_publisher).send_message(payload, event_type: event_type)
  end

  def self.discard_from_draft_content_store(base_path)
    return unless base_path

    if discard_draft_base_path_conflict?(base_path)
      message = "Cannot discard '#{base_path}' as there is an item occupying that base path"
      raise DiscardDraftBasePathConflictError.new(message)
    end
    Adapters::DraftContentStore.delete_content_item(base_path)
  end

  def self.draft_at_base_path?(base_path)
    return false unless base_path

    Edition.exists?(base_path: base_path, state: "draft")
  end

  def self.discard_draft_base_path_conflict?(base_path)
    return false unless base_path

    Edition.exists?(
      base_path: base_path,
      state: %w[draft published unpublished],
    )
  end

  # Sets the value for the GOVUK-Dependency-Resolution-Source-Content-Id header.
  #
  # The presence of this header should indicate that the request is a result of
  # the process of dependency resolution within the Publishing API. The value
  # of the header is the content id on which dependency resolution took place.
  #
  # Note that due to the possibility of recursive dependency resolution, there
  # doesn't have to be a direct dependency between the source content_id
  # (header value) and the respective content for the request.
  def self.set_govuk_dependency_resolution_source_content_id_header(value)
    GdsApi::GovukHeaders.set_header(
      :govuk_dependency_resolution_source_content_id,
      value,
    )
  end
end
