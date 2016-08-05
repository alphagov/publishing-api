class DownstreamPublishWorker
  attr_reader :content_item_id, :web_content_item, :payload_version, :message_queue_update_type, :update_dependencies

  include DownstreamQueue
  include Sidekiq::Worker
  include PerformAsyncInQueue

  sidekiq_options queue: HIGH_QUEUE

  def perform(args = {})
    assign_attributes(args.symbolize_keys)

    unless web_content_item
      raise AbortWorkerError.new("The content item for id: #{content_item_id} was not found")
    end

    if web_content_item.state != "published"
      raise AbortWorkerError.new("Will not downstream publish a content item that isn't published")
    end

    send_to_live_content_store if web_content_item.base_path
    enqueue_dependencies if update_dependencies
    broadcast_to_message_queue
  rescue AbortWorkerError => e
    Airbrake.notify_or_ignore(e)
  end

private

  def assign_attributes(attributes)
    @content_item_id = attributes.fetch(:content_item_id)
    @web_content_item = Queries::GetWebContentItems.find(content_item_id)
    @payload_version = attributes.fetch(:payload_version)
    @message_queue_update_type = attributes.fetch(:message_queue_update_type)
    @update_dependencies = attributes.fetch(:update_dependencies, true)
  end

  def send_to_live_content_store
    payload = Presenters::ContentStorePresenter.present(
      web_content_item,
      payload_version,
      state_fallback_order: live_content_store::DEPENDENCY_FALLBACK_ORDER
    )
    live_content_store.put_content_item(web_content_item.base_path, payload)
  end

  def broadcast_to_message_queue
    payload = Presenters::MessageQueuePresenter.present(
      web_content_item,
      state_fallback_order: [:published],
      update_type: message_queue_update_type,
    )
    PublishingAPI.service(:queue_publisher).send_message(payload)
  end

  def live_content_store
    Adapters::ContentStore
  end

  def enqueue_dependencies
    DependencyResolutionWorker.perform_async(
      content_store: live_content_store,
      fields: [:content_id],
      content_id: web_content_item.content_id,
      payload_version: payload_version,
    )
  end
end
