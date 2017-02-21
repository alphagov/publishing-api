require 'sidekiq-unique-jobs'

class DownstreamDraftWorker
  include DownstreamQueue
  include Sidekiq::Worker
  include PerformAsyncInQueue

  sidekiq_options queue: HIGH_QUEUE,
                  unique: :until_executing,
                  unique_args: :uniq_args

  def self.uniq_args(args)
    [
      args.first["content_id"] || args.first["content_item_id"],
      args.first["locale"],
      args.first.fetch("update_dependencies", true),
      name,
    ]
  end

  # FIXME: This worker can be initialised using a legacy interface with
  # "content_item_id" and the updated interface which uses "content_id" and
  # "locale". Both interfaces are supported until we are confident there are
  # no longer items in the sidekiq queue. They should all be long gone by
  # January 2017 and probably sooner.
  def perform(args = {})
    assign_attributes(args.symbolize_keys)

    unless edition
      raise AbortWorkerError.new("A downstreamable edition was not found for content_id: #{content_id} and locale: #{locale}")
    end

    unless dependency_resolution_source_content_id.nil?
      DownstreamService.set_govuk_dependency_resolution_source_content_id_header(
        dependency_resolution_source_content_id
      )
    end

    if edition.base_path
      DownstreamService.update_draft_content_store(
        DownstreamPayload.new(edition, payload_version, draft: true)
      )
    end

    enqueue_dependencies if update_dependencies
  rescue AbortWorkerError => e
    notify_airbrake(e, args)
  end

private

  attr_reader :content_id, :locale, :edition, :payload_version,
    :update_dependencies, :dependency_resolution_source_content_id, :orphaned_content_ids

  def assign_attributes(attributes)
    assign_backwards_compatible_content_item(attributes)
    @edition = Queries::GetEditionForContentStore.(content_id, locale, true)
    @payload_version = attributes.fetch(:payload_version)
    @orphaned_content_ids = attributes.fetch(:orphaned_content_ids, [])
    @update_dependencies = attributes.fetch(:update_dependencies, true)
    @dependency_resolution_source_content_id = attributes.fetch(
      :dependency_resolution_source_content_id,
      nil
    )
  end

  def assign_backwards_compatible_content_item(attributes)
    if attributes[:content_item_id]
      edition = Edition.find(attributes[:content_item_id])
      unless edition
        raise AbortWorkerError.new("A content item was not found for content_item_id: #{attributes[:content_item_id]}")
      end
      @content_id = edition.content_id
      @locale = edition.locale
    else
      @content_id = attributes.fetch(:content_id)
      @locale = attributes.fetch(:locale)
    end
  end

  def enqueue_dependencies
    DependencyResolutionWorker.perform_async(
      content_store: Adapters::DraftContentStore,
      fields: [:content_id],
      content_id: content_id,
      locale: locale,
      payload_version: payload_version,
      orphaned_content_ids: orphaned_content_ids,
    )
  end

  def notify_airbrake(error, parameters)
    Airbrake.notify(error, parameters: parameters)
  end
end
