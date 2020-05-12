require "sidekiq-unique-jobs"

class DownstreamDraftWorker
  include DownstreamQueue
  include Sidekiq::Worker
  include PerformAsyncInQueue

  sidekiq_options queue: HIGH_QUEUE,
                  unique: :until_executing,
                  unique_args: :uniq_args

  def self.uniq_args(args)
    [
      args.first["content_id"],
      args.first["locale"],
      args.first.fetch("update_dependencies", true),
      args.first.fetch("orphaned_content_ids", []),
      name,
    ]
  end

  def perform(args = {})
    assign_attributes(args.symbolize_keys)

    unless edition
      raise AbortWorkerError.new("A downstreamable edition was not found for content_id: #{content_id} and locale: #{locale}")
    end

    unless dependency_resolution_source_content_id.nil?
      DownstreamService.set_govuk_dependency_resolution_source_content_id_header(
        dependency_resolution_source_content_id,
      )
    end

    downstream_payload = DownstreamPayload.new(edition, payload_version, draft: true)

    update_expanded_links(downstream_payload)

    if edition.base_path
      DownstreamService.update_draft_content_store(downstream_payload)
    end

    enqueue_dependencies if update_dependencies
  rescue AbortWorkerError => e
    notify_airbrake(e, args)
  end

private

  attr_reader :content_id, :locale, :edition, :payload_version,
              :update_dependencies, :dependency_resolution_source_content_id, :orphaned_content_ids,
              :source_command, :source_fields

  def assign_attributes(attributes)
    @content_id = attributes.fetch(:content_id)
    @locale = attributes.fetch(:locale)
    @edition = Queries::GetEditionForContentStore.call(content_id, locale, true)
    @payload_version = Event.maximum_id
    @orphaned_content_ids = attributes.fetch(:orphaned_content_ids, [])
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
      content_store: Adapters::DraftContentStore,
      content_id: content_id,
      locale: locale,
      orphaned_content_ids: orphaned_content_ids,
      source_command: source_command,
      source_document_type: edition.document_type,
      source_fields: source_fields,
    )
  end

  def notify_airbrake(error, parameters)
    GovukError.notify(error, level: "warning", extra: parameters)
  end

  def update_expanded_links(downstream_payload)
    ExpandedLinks.locked_update(
      content_id: content_id,
      locale: locale,
      with_drafts: true,
      payload_version: payload_version,
      expanded_links: downstream_payload.expanded_links,
    )

    # When a document is only in draft it's expanded links can still be
    # accessed without drafts, so this is generates them as well.
    live_links = Presenters::Queries::ExpandedLinkSet.by_content_id(content_id,
                                                                    locale: locale,
                                                                    with_drafts: false)
    ExpandedLinks.locked_update(
      content_id: content_id,
      locale: locale,
      with_drafts: false,
      payload_version: payload_version,
      expanded_links: live_links.links,
    )
  end
end
