class DownstreamPublishWorker
  attr_reader :content_item_id, :send_to_content_store, :payload_version, :message_queue_update_type, :update_dependencies
  include Sidekiq::Worker
  include PerformAsyncInQueue

  HIGH_QUEUE = "downstream_high".freeze
  LOW_QUEUE = "downstream_low".freeze

  sidekiq_options queue: HIGH_QUEUE

  def perform(args = {})
    assign_attributes(args.symbolize_keys)

    unless web_content_item
      raise CommandError.new(
        code: 404,
        message: "The content item for id: #{content_item_id} was not found",
      )
    end

    unless content_item_state?(:published)
      raise CommandError.new(
        code: 500,
        message: "Will not downstream publish a content item that isn't published",
      )
    end

    send_to_live_content_store if send_to_content_store
    enqueue_dependencies if update_dependencies
    broadcast_to_message_queue
  end

private

  def assign_attributes(attributes)
    @content_item_id = attributes.fetch(:content_item_id)
    @payload_version = attributes.fetch(:payload_version)
    @message_queue_update_type = attributes.fetch(:message_queue_update_type)
    @send_to_content_store = attributes.fetch(:send_to_content_store, false)
    @update_dependencies = attributes.fetch(:update_dependencies, true)
  end

  def send_to_live_content_store
    payload = presented_content_store_payload
    base_path = payload.fetch(:base_path)
    live_content_store.put_content_item(base_path, payload)
  end

  def broadcast_to_message_queue
    payload = presented_message_queue_payload
    PublishingAPI.service(:queue_publisher).send_message(payload)
  end

  def live_content_store
    Adapters::ContentStore
  end

  def web_content_item
    @web_content_item ||= Queries::GetWebContentItems.(content_item_id).first
  end

  def content_item_state?(allowed_state)
    State.where(content_item_id: content_item_id).pluck(:name) == [allowed_state.to_s]
  end

  def presented_content_store_payload
    Presenters::ContentStorePresenter.present(
      web_content_item,
      payload_version,
      state_fallback_order: live_content_store::DEPENDENCY_FALLBACK_ORDER
    )
  end

  def presented_message_queue_payload
    Presenters::MessageQueuePresenter.present(
      web_content_item,
      state_fallback_order: [:published],
      update_type: message_queue_update_type,
    )
  end

  def enqueue_dependencies
    DependencyResolutionWorker.perform_async(
      content_store: live_content_store,
      fields: presented_content_store_payload.keys,
      content_id: web_content_item.content_id,
      payload_version: payload_version
    )
  end
end
