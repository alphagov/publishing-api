class RequeueContentJob
  include Sidekiq::Job
  include PerformAsyncInQueue

  sidekiq_options queue: :import

  def perform(edition_id, version, action = "bulk.reindex")
    edition = Edition.find(edition_id)
    presenter = DownstreamPayload.new(edition, version, draft: false)
    queue_payload = presenter.message_queue_payload
    service = PublishingAPI.service(:queue_publisher)

    # Requeue is considered a different event_type to major, minor etc
    # because we don't want to send additional email alerts to users.
    service.send_message(
      queue_payload,
      routing_key: "#{edition.schema_name}.#{action}",
      persistent: false,
    )
  end
end

RequeueContent = RequeueContentJob
