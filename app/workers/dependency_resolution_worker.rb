class DependencyResolutionWorker
  include Sidekiq::Worker
  include PerformAsyncInQueue

  sidekiq_options queue: :dependency_resolution

  def perform(args = {})
    assign_attributes(args.deep_symbolize_keys)

    dependencies.each do |dependency|
      send_downstream(dependency[:content_id], dependency[:locale], dependency[:priority])
    end

    orphaned_content_ids.each { |content_id| send_downstream(content_id, locale) }
  end

private

  attr_reader :content_id, :locale, :fields, :content_store, :orphaned_content_ids

  def assign_attributes(args)
    @content_id = args.fetch(:content_id)
    @locale = args.fetch(:locale)
    @content_store = args.fetch(:content_store).constantize
    @orphaned_content_ids = args.fetch(:orphaned_content_ids, [])
  end

  def send_downstream(content_id, locale, priority)
    downstream_draft(content_id, locale, priority)
    downstream_live(content_id, locale, priority)
  end

  def dependencies
    Queries::ContentDependencies.new(
      content_id: content_id,
      locale: locale,
      content_stores: draft? ? %w[draft live] : %w[live],
    ).priorities
  end

  def draft?
    content_store == Adapters::DraftContentStore
  end

  def downstream_draft(dependent_content_id, locale, priority)
    return unless draft?

    queue = high_priority?(priority) ? DownstreamDraftWorker::MEDIUM_QUEUE : DownstreamDraftWorker::LOW_QUEUE

    DownstreamDraftWorker.perform_async_in_queue(
      queue,
      content_id: dependent_content_id,
      locale: locale,
      update_dependencies: false,
      dependency_resolution_source_content_id: content_id,
    )
  end

  def downstream_live(dependent_content_id, locale, priority)
    return if draft?

    queue = high_priority?(priority) ? DownstreamLiveWorker::MEDIUM_QUEUE : DownstreamLiveWorker::LOW_QUEUE

    DownstreamLiveWorker.perform_async_in_queue(
      queue,
      content_id: dependent_content_id,
      locale: locale,
      message_queue_event_type: "links",
      update_dependencies: false,
      dependency_resolution_source_content_id: content_id,
    )
  end

  def high_priority?(priority)
    priority && priority == :high
  end
end
