class DownstreamPublishWorker
  attr_reader :content_item_id, :send_to_content_store, :payload_version, :message_queue_update_type
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
    broadcast_to_message_queue
  end

private

  def assign_attributes(attributes)
    @content_item_id = attributes.fetch(:content_item_id)
    @payload_version = attributes.fetch(:payload_version)
    @message_queue_update_type = attributes.fetch(:message_queue_update_type)
    @send_to_content_store = attributes[:send_to_content_store]
  end

  def send_to_live_content_store
    payload = presented_content_store
    base_path = payload.fetch(:base_path)
    live_content_store.put_content_item(base_path, payload)
  rescue => e
    handle_content_store_error(e)
  end

  def broadcast_to_message_queue
    payload = presented_message_queue
    PublishingAPI.service(:queue_publisher).send_message(payload)
  end

  def live_content_store
    Adapters::ContentStore
  end

  def handle_content_store_error(error)
    if !error.is_a?(CommandError) || error.code >= 500
      raise error
    else
      # @TODO
      # I'm not sure this is the correct explanation - feels like it was written
      # for 409s which are swallowed
      explanation = "The message is a duplicate and does not need to be retried"
      Airbrake.notify_or_ignore(error, parameters: { explanation: explanation })
    end
  end

  def web_content_item
    @web_content_item ||= Queries::GetWebContentItems.(content_item_id).first
  end

  def content_item_state?(allowed_state)
    State.where(content_item_id: content_item_id).pluck(:name) == [allowed_state.to_s]
  end

  def presented_content_store
    Presenters::ContentStorePresenter.present(
      web_content_item,
      payload_version,
      state_fallback_order: live_content_store::DEPENDENCY_FALLBACK_ORDER
    )
  end

  def presented_message_queue
    Presenters::MessageQueuePresenter.present(
      web_content_item,
      state_fallback_order: [:published],
      update_type: message_queue_update_type,
    )
  end
end
