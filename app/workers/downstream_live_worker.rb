require 'sidekiq-unique-jobs'

class DownstreamLiveWorker
  attr_reader :content_item_id, :web_content_item, :payload_version,
    :message_queue_update_type, :update_dependencies,
    :alert_on_invalid_state_error

  include DownstreamQueue
  include Sidekiq::Worker
  include PerformAsyncInQueue

  sidekiq_options queue: HIGH_QUEUE,
                  unique: :until_executing,
                  unique_args: :uniq_args

  def self.uniq_args(args)
    [
      args.first.fetch("content_item_id"),
      args.first.fetch("message_queue_update_type", nil),
      args.first.fetch("update_dependencies", true),
      name,
    ]
  end

  def perform(args = {})
    assign_attributes(args.symbolize_keys)

    unless web_content_item
      raise AbortWorkerError.new("The content item for id: #{content_item_id} was not found")
    end

    payload = DownstreamPayload.new(web_content_item, payload_version, Adapters::ContentStore::DEPENDENCY_FALLBACK_ORDER)

    DownstreamService.update_live_content_store(payload) if web_content_item.base_path

    if web_content_item.state == "published"
      update_type = message_queue_update_type || web_content_item.update_type
      DownstreamService.broadcast_to_message_queue(payload, update_type)
    end

    enqueue_dependencies if update_dependencies
  rescue DownstreamInvalidStateError => e
    alert_on_invalid_state_error ? notify_airbrake(e, args) : logger.warn(e.message)
  rescue AbortWorkerError => e
    notify_airbrake(e, args)
  end

private

  def assign_attributes(attributes)
    @content_item_id = attributes.fetch(:content_item_id)
    @web_content_item = Queries::GetWebContentItems.find(content_item_id)
    @payload_version = attributes.fetch(:payload_version)
    @message_queue_update_type = attributes.fetch(:message_queue_update_type, nil)
    @update_dependencies = attributes.fetch(:update_dependencies, true)
    @alert_on_invalid_state_error = attributes.fetch(:alert_on_invalid_state_error, true)
  end

  def enqueue_dependencies
    DependencyResolutionWorker.perform_async(
      content_store: Adapters::ContentStore,
      fields: [:content_id],
      content_id: web_content_item.content_id,
      payload_version: payload_version,
    )
  end

  def notify_airbrake(error, parameters)
    Airbrake.notify_or_ignore(error, parameters: parameters)
  end
end
