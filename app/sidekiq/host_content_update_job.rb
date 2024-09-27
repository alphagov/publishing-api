class HostContentUpdateJob < DependencyResolutionJob
private

  def downstream_live(dependent_content_id, locale)
    return if draft?

    puts "here in host content update job"

    host_edition = Document.find_by(content_id: dependent_content_id).live

    ChangeNote.create_from_edition({
                                     public_updated_at: Time.zone.now.to_s,
                                     update_type: "host_content",
                                     change_note: "content block #{embedded_edition.title} was updated to something",
                                   }, host_edition)

    # TODO: I don't know how we send this ChangeNote back to the relevant publisher.
    # Could they look for the host_content event?

    DownstreamLiveJob.perform_async_in_queue(
      DownstreamLiveJob::LOW_QUEUE,
      "content_id" => dependent_content_id,
      "locale" => locale,
      "message_queue_event_type" => "host_content",
      "update_dependencies" => false,
      "dependency_resolution_source_content_id" => content_id,
      "source_command" => source_command,
      "source_fields" => source_fields,
    )
  end
end
