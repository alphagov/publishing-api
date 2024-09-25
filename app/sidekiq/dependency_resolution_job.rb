class DependencyResolutionJob
  include Sidekiq::Job
  include PerformAsyncInQueue

  sidekiq_options queue: :dependency_resolution

  def perform(args = {})
    assign_attributes(args)

    send_source_stats

    dependencies.each do |(content_id, locale)|
      send_downstream(content_id, locale)
    end

    orphaned_content_ids_for_locale.each { |content_id| send_downstream(content_id, locale) }
  end

private

  attr_reader :content_id,
              :locale,
              :content_store,
              :orphaned_content_ids,
              :source_command,
              :source_document_type,
              :source_fields

  def assign_attributes(args)
    @content_id = args.fetch("content_id")
    @locale = args.fetch("locale")
    @content_store = args.fetch("content_store").constantize
    @orphaned_content_ids = args.fetch("orphaned_content_ids", [])
    @source_command = args["source_command"]
    @source_document_type = args["source_document_type"]
    @source_fields = args.fetch("source_fields", [])
  end

  def orphaned_content_ids_for_locale
    Document
      .distinct
      .joins(:editions)
      .where(editions: { content_store: content_stores },
             content_id: orphaned_content_ids,
             locale:)
      .pluck(:content_id)
  end

  def content_stores
    draft? ? %w[draft live] : %w[live]
  end

  def send_source_stats
    prefix = "dependency_resolution.source"

    GovukStatsd.increment("#{prefix}.command.#{source_command}") if source_command

    GovukStatsd.increment("#{prefix}.document_type.#{source_document_type}") if source_document_type

    source_fields.each do |field|
      GovukStatsd.increment("#{prefix}.field.#{field}")
    end
  end

  def send_downstream(content_id, locale)
    downstream_draft(content_id, locale)
    downstream_live(content_id, locale)
  end

  def dependencies
    Queries::ContentDependencies.new(
      content_id:,
      locale:,
      content_stores:,
    ).call
  end

  def draft?
    content_store == Adapters::DraftContentStore
  end

  def downstream_draft(dependent_content_id, locale)
    return unless draft?

    DownstreamDraftWorker.perform_async_in_queue(
      DownstreamDraftWorker::LOW_QUEUE,
      "content_id" => dependent_content_id,
      "locale" => locale,
      "update_dependencies" => false,
      "dependency_resolution_source_content_id" => content_id,
      "source_command" => source_command,
      "source_fields" => source_fields,
    )
  end

  def downstream_live(dependent_content_id, locale)
    return if draft?

    DownstreamLiveWorker.perform_async_in_queue(
      DownstreamLiveWorker::LOW_QUEUE,
      "content_id" => dependent_content_id,
      "locale" => locale,
      "message_queue_event_type" => "links",
      "update_dependencies" => false,
      "dependency_resolution_source_content_id" => content_id,
      "source_command" => source_command,
      "source_fields" => source_fields,
    )
  end
end

DependencyResolutionWorker = DependencyResolutionJob
