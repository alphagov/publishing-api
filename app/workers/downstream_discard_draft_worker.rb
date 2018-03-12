class DownstreamDiscardDraftWorker
  include DownstreamQueue
  include Sidekiq::Worker
  include PerformAsyncInQueue

  sidekiq_options queue: HIGH_QUEUE

  def perform(args = {})
    assign_attributes(args.symbolize_keys)

    current_path = edition.try(:base_path)
    if current_path
      DownstreamService.update_draft_content_store(downstream_payload)

      if base_path && current_path != base_path
        DownstreamService.discard_from_draft_content_store(base_path)
      end
    elsif base_path
      DownstreamService.discard_from_draft_content_store(base_path)
    end

    update_expanded_links

    enqueue_dependencies if update_dependencies
  rescue DiscardDraftBasePathConflictError => e
    logger.warn(e.message)
  end

private

  attr_reader :base_path, :content_id, :locale, :edition,
    :payload_version, :update_dependencies

  def assign_attributes(attributes)
    @base_path = attributes.fetch(:base_path)
    @content_id = attributes.fetch(:content_id)
    @locale = attributes.fetch(:locale)
    @payload_version = Event.payload_version(content_id)
    @edition = Queries::GetEditionForContentStore.(content_id, locale, true)
    @update_dependencies = attributes.fetch(:update_dependencies, true)
  end

  def enqueue_dependencies
    DependencyResolutionWorker.perform_async(
      content_store: Adapters::DraftContentStore,
      fields: [:content_id],
      content_id: content_id,
      locale: locale,
    )
  end

  def update_expanded_links
    if edition
      ExpandedLinks.locked_update(
        content_id: content_id,
        locale: locale,
        with_drafts: true,
        payload_version: payload_version,
        expanded_links: downstream_payload.expanded_links,
      )
    else
      ExpandedLinks.where(
        content_id: content_id,
        locale: locale,
        with_drafts: true,
      ).where("payload_version < ?", payload_version).delete_all
    end
  end

  def downstream_payload
    @downstream_payload ||= DownstreamPayload.new(edition, payload_version, draft: true)
  end
end
