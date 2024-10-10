class HostContentUpdateJob < DependencyResolutionJob
private

  def downstream_live(dependent_content_id, locale)
    return if draft?

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
