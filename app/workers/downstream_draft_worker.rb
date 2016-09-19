require 'sidekiq-unique-jobs'

class DownstreamDraftWorker
  attr_reader :web_content_item, :content_item_id, :payload_version,
    :update_dependencies, :alert_on_invalid_state_error,
    :dependency_resolution_source_content_id

  include DownstreamQueue
  include Sidekiq::Worker
  include PerformAsyncInQueue

  sidekiq_options queue: HIGH_QUEUE,
                  unique: :until_executing,
                  unique_args: :uniq_args

  def self.uniq_args(args)
    [
      args.first.fetch("content_item_id"),
      args.first.fetch("update_dependencies", true),
      name,
    ]
  end

  def perform(args = {})
    assign_attributes(args.symbolize_keys)

    unless web_content_item
      raise AbortWorkerError.new("The content item for id: #{content_item_id} was not found")
    end

    if web_content_item.base_path
      DownstreamService.update_draft_content_store(
        DownstreamPayload.new(web_content_item, payload_version, Adapters::DraftContentStore::DEPENDENCY_FALLBACK_ORDER)
      )
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
    @update_dependencies = attributes.fetch(:update_dependencies, true)
    @alert_on_invalid_state_error = attributes.fetch(:alert_on_invalid_state_error, true)
    @dependency_resolution_source_content_id = attributes.fetch(
      :dependency_resolution_source_content_id,
      nil
    )
  end

  def enqueue_dependencies
    DependencyResolutionWorker.perform_async(
      content_store: Adapters::DraftContentStore,
      fields: [:content_id],
      content_id: web_content_item.content_id,
      payload_version: payload_version
    )
  end

  def notify_airbrake(error, parameters)
    Airbrake.notify_or_ignore(error, parameters: parameters)
  end
end
