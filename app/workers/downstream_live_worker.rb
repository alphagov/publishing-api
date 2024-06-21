require "sidekiq-unique-jobs"

class DownstreamLiveWorker
  include DownstreamQueue
  include Sidekiq::Worker
  include PerformAsyncInQueue

  sidekiq_options queue: HIGH_QUEUE,
                  lock: :until_executing,
                  lock_args_method: :uniq_args,
                  on_conflict: :log

  def self.uniq_args(args)
    [
      args.first["content_id"],
      args.first["locale"],
      args.first["message_queue_event_type"],
      args.first.fetch("update_dependencies", true),
      args.first.fetch("orphaned_content_ids", []),
      name,
    ]
  end

  def perform(args = {})
    Rails.logger.info("DownstreamLiveWorker#perform: 1")
    assign_attributes(args.symbolize_keys)

    Rails.logger.info("DownstreamLiveWorker#perform: 2")

    unless edition
      Rails.logger.info("DownstreamLiveWorker#perform: 3")
      raise AbortWorkerError, "A downstreamable edition was not found for content_id: #{content_id} and locale: #{locale}"
    end

    Rails.logger.info("DownstreamLiveWorker#perform: 4")
    unless dependency_resolution_source_content_id.nil?
      Rails.logger.info("DownstreamLiveWorker#perform: 5")
      DownstreamService.set_govuk_dependency_resolution_source_content_id_header(
        dependency_resolution_source_content_id,
      )
      Rails.logger.info("DownstreamLiveWorker#perform: 6")
    end

    payload = DownstreamPayload.new(edition, payload_version, draft: false)
    Rails.logger.info("DownstreamLiveWorker#perform: 7")

    update_expanded_links(payload)
    Rails.logger.info("DownstreamLiveWorker#perform: 8")
    DownstreamService.update_live_content_store(payload) if edition.base_path
    Rails.logger.info("DownstreamLiveWorker#perform: 9")

    if %w[published unpublished].include?(edition.state)
      Rails.logger.info("DownstreamLiveWorker#perform: 10")
      event_type = message_queue_event_type || edition.update_type
      Rails.logger.info(
        "DownstreamLiveWorker#perform:" \
        "Broadcasting #{content_id}@#{payload_version} to message queue as type #{event_type}",
      )
      DownstreamService.broadcast_to_message_queue(payload, event_type)
      Rails.logger.info("DownstreamLiveWorker#perform: 11")
    end

    Rails.logger.info("DownstreamLiveWorker#perform: 12")
    enqueue_dependencies if update_dependencies
    Rails.logger.info("DownstreamLiveWorker#perform: 13")
  rescue AbortWorkerError => e
    notify_airbrake(e, args)
  end

private

  attr_reader :content_id,
              :locale,
              :edition,
              :payload_version,
              :message_queue_event_type,
              :update_dependencies,
              :dependency_resolution_source_content_id,
              :orphaned_content_ids,
              :source_command,
              :source_fields

  def assign_attributes(attributes)
    @content_id = attributes.fetch(:content_id)
    @locale = attributes.fetch(:locale)
    @payload_version = Event.maximum_id
    @edition = Queries::GetEditionForContentStore.call(content_id, locale, include_draft: false)
    @orphaned_content_ids = attributes.fetch(:orphaned_content_ids, [])
    @message_queue_event_type = attributes.fetch(:message_queue_event_type, nil)
    @update_dependencies = attributes.fetch(:update_dependencies, true)
    @dependency_resolution_source_content_id = attributes.fetch(
      :dependency_resolution_source_content_id,
      nil,
    )
    @source_command = attributes[:source_command]
    @source_fields = attributes.fetch(:source_fields, [])
  end

  def enqueue_dependencies
    DependencyResolutionWorker.perform_async(
      "content_store" => "Adapters::ContentStore",
      "content_id" => content_id,
      "locale" => locale,
      "orphaned_content_ids" => orphaned_content_ids,
      "source_command" => source_command,
      "source_document_type" => edition.document_type,
      "source_fields" => source_fields,
    )
  end

  def notify_airbrake(error, parameters)
    GovukError.notify(error, level: "warning", extra: parameters)
  end

  def update_expanded_links(downstream_payload)
    ExpandedLinks.locked_update(
      content_id:,
      locale:,
      with_drafts: false,
      payload_version:,
      expanded_links: downstream_payload.expanded_links,
    )
  end
end
