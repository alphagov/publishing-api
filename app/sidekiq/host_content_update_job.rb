class HostContentUpdateJob < DependencyResolutionJob
private

  def downstream_live(dependent_content_id, locale)
    return if draft?

    event_payload = {
      content_id: dependent_content_id,
      locale:,
      message: "Host content updated by content block update",
      source_block: {
        title: source_edition.title,
        content_id: source_edition.content_id,
        document_type: source_edition.document_type,
        updated_by_user_uid: source_edition_publication_event&.user_uid,
      },
    }

    EventLogger.log_command(self.class, event_payload) do |_event|
      DownstreamLiveJob.perform_async_in_queue(
        DownstreamLiveJob::HIGH_QUEUE,
        "content_id" => dependent_content_id,
        "locale" => locale,
        "message_queue_event_type" => source_edition.update_type,
        "update_dependencies" => false,
        "dependency_resolution_source_content_id" => content_id,
        "source_command" => source_command,
        "source_fields" => source_fields,
      )
    end
  end

  def source_edition_publication_event
    @source_edition_publication_event ||= Event
      .where(action: "Publish", content_id:)
      .order(created_at: :desc)
      .first
  end

  def source_edition
    @source_edition ||= Document.find_by(content_id:).live
  end

  def dependencies
    Queries::ContentDependencies.new(
      content_id:,
      locale: nil,
      content_stores:,
    ).call
  end
end
