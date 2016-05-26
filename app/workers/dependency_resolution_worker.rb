class DependencyResolutionWorker
  include Sidekiq::Worker
  include PerformAsyncInQueue

  sidekiq_options queue: :dependency_resolution

  def perform(args = {})
    assign_attributes(args.deep_symbolize_keys)

    content_item_dependees.each do |dependent_content_id|
      present_content_store(dependent_content_id)
    end
  end

private

  attr_reader :content_id, :fields, :request_uuid, :content_store, :payload_version

  def assign_attributes(args)
    @content_id = args.fetch(:content_id)
    @fields = args.fetch(:fields, []).map(&:to_sym)
    @request_uuid = args.fetch(:request_uuid)
    @content_store = args.fetch(:content_store).constantize
    @payload_version = args.fetch(:payload_version)
  end

  def content_item_dependees
    Queries::ContentDependencies.new(content_id: content_id,
                                     fields: fields,
                                     dependent_lookup: Queries::GetDependees.new).call
  end

  def present_content_store(dependent_content_id)
    latest_content_item = Queries::GetLatest.call(
      ContentItem.where(content_id: dependent_content_id)
    ).last

    return unless latest_content_item

    PresentedContentStoreWorker.perform_async_in_queue(
      PresentedContentStoreWorker::LOW_QUEUE,
      content_store: content_store,
      payload: { content_item_id: latest_content_item.id, payload_version: payload_version },
      request_uuid: request_uuid,
      enqueue_dependency_check: false,
    )
  end
end
