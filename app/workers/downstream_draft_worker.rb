class DownstreamDraftWorker
  attr_reader :web_content_item, :content_item_id, :payload_version, :update_dependencies

  include DownstreamQueue
  include Sidekiq::Worker
  include PerformAsyncInQueue

  sidekiq_options queue: HIGH_QUEUE

  def perform(args = {})
    assign_attributes(args.symbolize_keys)

    unless web_content_item
      raise AbortWorkerError.new("The content item for id: #{content_item_id} was not found")
    end

    if web_content_item.base_path
      downstream.send_to_draft_content_store(web_content_item, payload_version)
    end
    enqueue_dependencies if update_dependencies
  rescue AbortWorkerError, DownstreamInvariantError => e
    Airbrake.notify_or_ignore(e)
  end

private

  def assign_attributes(attributes)
    @content_item_id = attributes.fetch(:content_item_id)
    @web_content_item = Queries::GetWebContentItems.find(content_item_id)
    @payload_version = attributes.fetch(:payload_version)
    @update_dependencies = attributes.fetch(:update_dependencies, true)
  end

  def enqueue_dependencies
    DependencyResolutionWorker.perform_async(
      content_store: Adapters::DraftContentStore,
      fields: [:content_id],
      content_id: web_content_item.content_id,
      payload_version: payload_version
    )
  end
end
