class DependencyResolutionWorker
  include Sidekiq::Worker
  include PerformAsyncInQueue

  sidekiq_options queue: :dependency_resolution

  def perform(args = {})
    assign_attributes(args.deep_symbolize_keys)

    dependencies.each do |(content_id, locale)|
      send_downstream(content_id, locale)
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

  def send_downstream(content_id, locale)
    downstream_draft(content_id, locale)
    downstream_live(content_id, locale)
  end

  def dependencies
    Queries::ContentDependencies.new(
      content_id: content_id,
      locale: locale,
      content_stores: draft? ? %w[draft live] : %w[live],
    ).call
  end

  def draft?
    content_store == Adapters::DraftContentStore
  end

  def downstream_draft(dependent_content_id, locale)
    return unless draft?

    DownstreamDraftWorker.perform_async_in_queue(
      queue(dependent_content_id),
      content_id: dependent_content_id,
      locale: locale,
      update_dependencies: false,
      dependency_resolution_source_content_id: content_id,
    )
  end

  def downstream_live(dependent_content_id, locale)
    return if draft?

    DownstreamLiveWorker.perform_async_in_queue(
      queue(dependent_content_id),
      content_id: dependent_content_id,
      locale: locale,
      message_queue_event_type: "links",
      update_dependencies: false,
      dependency_resolution_source_content_id: content_id,
    )
  end

  def queue(dependent_content_id)
    return DownstreamDraftWorker::MEDIUM_QUEUE if high_priority?(dependent_content_id)
    DownstreamDraftWorker::LOW_QUEUE
  end

  def high_priority?(dependent_content_id)
    high_priority_links.include?(dependent_content_id)
  end

  def high_priority_links
    @high_priority_links ||= edition.links.where(link_type: rules).pluck(:target_content_id)
  end

  def edition
    @edition ||= Edition.with_document.where("documents.content_id": @content_id).last
  end

  def rules
    ExpansionRules::HIGH_PRIORITY_LINKS
  end
end
